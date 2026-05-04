#!/usr/bin/env bash

set -u

copy_to_clipboard() {
    local value="$1"
    if command -v wl-copy >/dev/null 2>&1; then
        printf '%s' "$value" | wl-copy
    elif command -v xclip >/dev/null 2>&1; then
        printf '%s' "$value" | xclip -selection clipboard
    elif command -v xsel >/dev/null 2>&1; then
        printf '%s' "$value" | xsel --clipboard --input
    fi
}

show_mode_menu() {
    local mode="$1"
    local prompt="Scientific"
    local message="式を入力して Enter（結果はクリップボードにコピーされます）"

    if [ "$mode" = "programmer" ]; then
        prompt="Programmer"
        message="整数式 / ASCII 変換（例: (0xff & 0b1010) << 2, ascii:Hello, char:65）"
    fi

    printf '\0prompt\x1f%s\n' "$prompt"
    printf '\0message\x1f%s\n' "$message"
    printf '\0data\x1f%s\n' "$mode"

    printf 'Scientific mode\0info\x1fmode:scientific\n'
    printf 'Programmer mode\0info\x1fmode:programmer\n'

    if [ "$mode" = "programmer" ]; then
        printf '(0xff & 0b1010) << 2\0info\x1fexpr:(0xff & 0b1010) << 2\n'
        printf '(255 ^ 15) + 1\0info\x1fexpr:(255 ^ 15) + 1\n'
        printf 'C + 0x20\0info\x1fexpr:C + 0x20\n'
        printf 'ascii:Hello\0info\x1fexpr:ascii:Hello\n'
        printf 'char:65\0info\x1fexpr:char:65\n'
    else
        printf 'sin(pi/3)\0info\x1fexpr:sin(pi/3)\n'
        printf 'sqrt(2)^2\0info\x1fexpr:sqrt(2)^2\n'
        printf '5 km in mi\0info\x1fexpr:5 km in mi\n'
    fi
}

evaluate_scientific() {
    local expression="$1"
    LC_ALL=C qalc -t -- "$expression" 2>/dev/null | head -n 1
}

evaluate_programmer() {
    local expression="$1"
    python3 - "$expression" <<'PY'
import ast
import sys

expr = sys.argv[1].strip()
if not expr:
    sys.exit(1)

allowed_binops = (
    ast.Add, ast.Sub, ast.Mult, ast.FloorDiv, ast.Mod, ast.LShift, ast.RShift, ast.BitOr, ast.BitXor, ast.BitAnd
)
allowed_unary = (ast.UAdd, ast.USub, ast.Invert)

def eval_node(node):
    if isinstance(node, ast.Expression):
        return eval_node(node.body)

    if isinstance(node, ast.Constant):
        if isinstance(node.value, bool) or not isinstance(node.value, int):
            raise ValueError
        return node.value

    if isinstance(node, ast.Name):
        if len(node.id) == 1 and node.id.isascii() and node.id.isprintable():
            return ord(node.id)
        raise ValueError

    if isinstance(node, ast.UnaryOp) and isinstance(node.op, allowed_unary):
        value = eval_node(node.operand)
        if isinstance(node.op, ast.UAdd):
            return +value
        if isinstance(node.op, ast.USub):
            return -value
        return ~value

    if isinstance(node, ast.BinOp) and isinstance(node.op, allowed_binops):
        left = eval_node(node.left)
        right = eval_node(node.right)

        if isinstance(node.op, ast.Add):
            return left + right
        if isinstance(node.op, ast.Sub):
            return left - right
        if isinstance(node.op, ast.Mult):
            return left * right
        if isinstance(node.op, ast.FloorDiv):
            return left // right
        if isinstance(node.op, ast.Mod):
            return left % right
        if isinstance(node.op, ast.LShift):
            return left << right
        if isinstance(node.op, ast.RShift):
            return left >> right
        if isinstance(node.op, ast.BitOr):
            return left | right
        if isinstance(node.op, ast.BitXor):
            return left ^ right
        return left & right

    raise ValueError

def safe_eval_int(source):
    tree = ast.parse(source, mode="eval")
    return eval_node(tree)

def fmt_signed(value, base):
    if value < 0:
        return "-" + format(-value, base)
    return format(value, base)

def ascii_display(value):
    if 32 <= value <= 126:
        return chr(value)
    if value in (9, 10, 13):
        return {9: "\\t", 10: "\\n", 13: "\\r"}[value]
    if 0 <= value <= 127:
        return f"control(0x{value:02x})"
    return "n/a"

try:
    if expr.lower().startswith("ascii:"):
        text = expr.split(":", 1)[1]
        if text == "":
            raise ValueError
        dec_values = [str(ord(ch)) for ch in text]
        hex_values = [f"0x{ord(ch):02x}" for ch in text]
        print(f"text: {text} | dec: {' '.join(dec_values)} | hex: {' '.join(hex_values)}")
        sys.exit(0)

    if expr.lower().startswith("char:") or expr.lower().startswith("chr:"):
        numeric_expr = expr.split(":", 1)[1].strip()
        if numeric_expr == "":
            raise ValueError
        result = safe_eval_int(numeric_expr)
        if result < 0 or result > 127:
            print(f"dec: {result} | ascii: n/a (outside 0..127)")
            sys.exit(0)
        print(f"dec: {result} | ascii: {ascii_display(result)}")
        sys.exit(0)

    result = safe_eval_int(expr)
except Exception:
    sys.exit(1)

print(
    f"dec: {result} | hex: 0x{fmt_signed(result, 'x')} | oct: 0o{fmt_signed(result, 'o')} | "
    f"bin: 0b{fmt_signed(result, 'b')} | ascii: {ascii_display(result)}"
)
PY
}

evaluate_expression() {
    local mode="$1"
    local expression="$2"

    if [ "$mode" = "programmer" ]; then
        evaluate_programmer "$expression"
        return
    fi

    evaluate_scientific "$expression"
}

retv="${ROFI_RETV:-0}"
input="${1:-${ROFI_INPUT:-}}"
info="${ROFI_INFO:-}"
mode="${ROFI_DATA:-programmer}"

if [ "$retv" = "0" ]; then
    show_mode_menu "$mode"
    exit 0
fi

if [ "$retv" = "1" ] || [ "$retv" = "2" ]; then
    if [ -n "$info" ] && [ "${info#mode:}" != "$info" ]; then
        mode="${info#mode:}"
        show_mode_menu "$mode"
        exit 0
    fi

    if [ -n "$info" ] && [ "${info#expr:}" != "$info" ]; then
        input="${info#expr:}"
    fi

    if [ -z "${input:-}" ]; then
        show_mode_menu "$mode"
        exit 0
    fi

    result="$(evaluate_expression "$mode" "$input" 2>/dev/null | head -n 1)"
    if [ -z "$result" ]; then
        show_mode_menu "$mode"
        printf '\0message\x1f無効な式です\n'
        exit 0
    fi

    copy_to_clipboard "$result"
    printf '\0message\x1f%s\n' "${result} (copied)"
    printf '\0data\x1f%s\n' "$mode"
    echo "$result"
fi
