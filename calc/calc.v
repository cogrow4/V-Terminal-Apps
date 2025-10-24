import os
import math

fn main() {
    clear_screen()
    println('🧮 Calc - The Ultimate Terminal Calculator')
    println('-----------------------------------------')
    println('Operations: +, -, *, /, ^ (power), sqrt, sin, cos, tan')
    println('Type "exit" to quit\n')
    
    for {
        print('> ')
        input := os.get_line().trim_space()
        
        if input == 'exit' {
            println('\n👋 Happy calculating! Goodbye!')
            break
        }
        
        if input == '' {
            continue
        }
        
        // Handle special functions
        if input.starts_with('sqrt ') {
            num_str := input[5..].trim_space()
            num := num_str.f64()
            if num_str.len > 0 && num_str[0].is_digit() {
                println('√$num = ${math.sqrt(num):.4f}')
            } else {
                println('❌ Invalid input for square root')
            }
            continue
        } else if input.starts_with('sin ') {
            num_str := input[4..].trim_space()
            num := num_str.f64()
            if num_str.len > 0 && num_str[0].is_digit() {
                println('sin(${num}°) = ${math.sin(math.radians(num)):.4f}')
            } else {
                println('❌ Invalid input for sine')
            }
            continue
        } else if input.starts_with('cos ') {
            num_str := input[4..].trim_space()
            num := num_str.f64()
            if num_str.len > 0 && num_str[0].is_digit() {
                println('cos(${num}°) = ${math.cos(math.radians(num)):.4f}')
            } else {
                println('❌ Invalid input for cosine')
            }
            continue
        } else if input.starts_with('tan ') {
            num_str := input[4..].trim_space()
            num := num_str.f64()
            if num_str.len > 0 && num_str[0].is_digit() {
                println('tan(${num}°) = ${math.tan(math.radians(num)):.4f}')
            } else {
                println('❌ Invalid input for tangent')
            }
            continue
        }
        
        // Handle basic arithmetic
        mut result := 0.0
        mut op := ''
        
        // Find the operator
        for c in ['+', '-', '*', '/', '^'] {
            if input.contains(c) {
                op = c.str()
                break
            }
        }
        
        if op == '' {
            println('❌ Invalid operation. Supported: +, -, *, /, ^, sqrt, sin, cos, tan')
            continue
        }
        
        parts := input.split(op)
        if parts.len != 2 {
            println('❌ Invalid expression')
            continue
        }
        
        a_str := parts[0].trim_space()
        b_str := parts[1].trim_space()
        
        if a_str.len == 0 || !a_str[0].is_digit() || b_str.len == 0 || !b_str[0].is_digit() {
            println('❌ Invalid number format')
            continue
        }
        
        a := a_str.f64()
        b := b_str.f64()
        
        match op {
            '+' { result = a + b }
            '-' { result = a - b }
            '*' { result = a * b }
            '/' { 
                if b == 0 {
                    println('❌ Cannot divide by zero')
                    continue
                }
                result = a / b 
            }
            '^' { result = math.pow(a, b) }
            else {
                println('❌ Unsupported operation')
                continue
            }
        }
        
        println('= $result')
    }
}

fn clear_screen() {
    print('\x1b[2J\x1b[H')
}
