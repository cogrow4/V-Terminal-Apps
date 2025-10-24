import os
import json
import time

struct Transaction {
    id          int
    description string
    amount      f64
    category    string
    date        string
    type        string // "income" or "expense"
}

struct Budget {
    category string
    mut:
    limit    f64
    spent    f64
}

fn main() {
    mut transactions := load_transactions()
    mut budgets := load_budgets()

    for {
        clear_screen()
        println('💰 Cash - Your Budget Tracker')
        println('----------------------------')

        total_income := calculate_total(transactions, 'income')
        total_expenses := calculate_total(transactions, 'expense')
        balance := total_income - total_expenses

        println('📊 Summary:')
        println('  Income:    \$${total_income:.2f}')
        println('  Expenses:  \$${total_expenses:.2f}')
        println('  Balance:   \$${balance:.2f}')

        if budgets.len > 0 {
            println('\n📈 Budget Status:')
            for budget in budgets {
                percentage := if budget.limit > 0 { (budget.spent / budget.limit) * 100 } else { 0.0 }
                status := if percentage > 90 { '🔴' } else if percentage > 70 { '🟡' } else { '🟢' }
                println('  $status ${budget.category}: \$${budget.spent:.2f}/\$${budget.limit:.2f} (${percentage:.1f}%)')
            }
        }

        println('\nCommands:')
        println('  add income   - Add income')
        println('  add expense  - Add expense')
        println('  list         - List all transactions')
        println('  budget       - Set budget limits')
        println('  report       - Generate spending report')
        println('  search       - Search transactions')
        println('  delete       - Delete transaction')
        println('  quit         - Exit')

        print('\n> ')
        input := os.get_line().trim_space()

        match input {
            'add income' { add_transaction(mut transactions, mut budgets, 'income') }
            'add expense' { add_transaction(mut transactions, mut budgets, 'expense') }
            'list' { list_transactions(transactions) }
            'budget' { manage_budgets(mut budgets, transactions) }
            'report' { generate_report(transactions) }
            'search' { search_transactions(transactions) }
            'delete' { delete_transaction(mut transactions) }
            'quit' {
                save_transactions(transactions)
                save_budgets(budgets)
                println('\n💾 Data saved. Goodbye!')
                break
            }
            else {
                println('\n❌ Unknown command. Press Enter to continue...')
                os.get_line()
            }
        }
    }
}

fn add_transaction(mut transactions []Transaction, mut budgets []Budget, trans_type string) {
    clear_screen()
    title := if trans_type == 'income' { '💰 Add Income' } else { '💸 Add Expense' }
    println('$title')
    println(repeat_char('-', title.len + 1))

    print('Description: ')
    description := os.get_line().trim_space()

    if description == '' {
        println('\n❌ Description cannot be empty')
        time.sleep(1)
        return
    }

    print('Amount: $')
    amount_str := os.get_line().trim_space()
    amount := amount_str.f64()

    if amount <= 0 {
        println('\n❌ Amount must be greater than 0')
        time.sleep(1)
        return
    }

    print('Category: ')
    category := os.get_line().trim_space()

    if category == '' {
        println('\n❌ Category cannot be empty')
        time.sleep(1)
        return
    }

    new_id := if transactions.len > 0 { transactions.last().id + 1 } else { 1 }
    transaction := Transaction{
        id: new_id,
        description: description,
        amount: amount,
        category: category,
        date: time.now().format(),
        type: trans_type
    }

    transactions << transaction

    // Update budget tracking if this is an expense
    if trans_type == 'expense' {
        for mut budget in budgets {
            if budget.category == category {
                budget.spent += amount
                break
            }
        }
    }

    println('\n✅ ${trans_type.title()} added successfully!')
    time.sleep(1)
}

fn list_transactions(transactions []Transaction) {
    clear_screen()
    println('📋 All Transactions')
    println('-------------------')

    if transactions.len == 0 {
        println('No transactions found.')
    } else {
        // Sort by date (newest first) - V syntax
        mut sorted := transactions.clone()
        sorted.sort(b.date > a.date)

        for transaction in sorted {
            symbol := if transaction.type == 'income' { '💰' } else { '💸' }
            amount_str := '\$${transaction.amount:.2f}'
            println('$symbol ${transaction.date} - ${transaction.description} (${transaction.category}) $amount_str')
        }
    }

    println('\nPress Enter to continue...')
    os.get_line()
}

fn manage_budgets(mut budgets []Budget, transactions []Transaction) {
    clear_screen()
    println('📈 Budget Management')
    println('--------------------')

    if budgets.len == 0 {
        println('No budgets set. Create some below!')
    } else {
        println('Current budgets:')
        for i, budget in budgets {
            println('${i+1}. ${budget.category}: \$${budget.limit:.2f}')
        }
        println('')
    }

    println('Commands:')
    println('  add <category> <limit>  - Add new budget')
    println('  remove <number>         - Remove budget')
    println('  update <number> <limit> - Update budget limit')
    println('  back                    - Go back')

    print('\n> ')
    input := os.get_line().trim_space()

    if input == 'back' {
        return
    } else if input.starts_with('add ') {
        parts := input[4..].split(' ')
        if parts.len >= 2 {
            category := parts[0]
            limit_str := parts[1]
            limit := limit_str.f64()

            if limit_str == '' {
                println('\n❌ Please enter a valid budget limit')
                time.sleep(1)
                return
            }

            if limit <= 0 {
                println('\n❌ Budget limit must be greater than 0')
                time.sleep(1)
                return
            }

            // Check if budget already exists
            for budget in budgets {
                if budget.category == category {
                    println('\n❌ Budget for $category already exists')
                    time.sleep(1)
                    return
                }
            }

            budget := Budget{
                category: category,
                limit: limit,
                spent: 0.0
            }
            budgets << budget
            println('\n✅ Budget for $category added!')
        } else {
            println('\n❌ Usage: add <category> <limit>')
        }
    } else if input.starts_with('remove ') {
        num_str := input[7..].trim_space()
        num := num_str.int()

        if num <= 0 {
            println('\n❌ Please enter a valid budget number')
            time.sleep(1)
            return
        }

        if num > 0 && num <= budgets.len {
            removed := budgets[num-1].category
            budgets.delete(num-1)
            println('\n✅ Budget for $removed removed!')
        } else {
            println('\n❌ Invalid budget number. Please enter a number between 1 and ${budgets.len}')
        }
    } else if input.starts_with('update ') {
        parts := input[7..].split(' ')
        if parts.len >= 2 {
            num_str := parts[0]
            limit_str := parts[1]
            num := num_str.int()
            limit := limit_str.f64()

            if num <= 0 {
                println('\n❌ Please enter a valid budget number')
                time.sleep(1)
                return
            }

            if num > 0 && num <= budgets.len {
                if limit <= 0 {
                    println('\n❌ Budget limit must be greater than 0')
                    time.sleep(1)
                    return
                }

                budgets[num-1].limit = limit
                println('\n✅ Budget ${budgets[num-1].category} updated to \$${limit:.2f}')
            } else {
                println('\n❌ Invalid budget number. Please enter a number between 1 and ${budgets.len}')
            }
        } else {
            println('\n❌ Usage: update <number> <limit>')
        }
    } else {
        println('\n❌ Unknown command')
    }

    time.sleep(1)
}

fn generate_report(transactions []Transaction) {
    clear_screen()
    println('📊 Spending Report')
    println('------------------')

    if transactions.len == 0 {
        println('No transactions available for report.')
    } else {
        // Calculate totals by category
        mut category_totals := map[string]f64{}
        mut category_counts := map[string]int{}

        for transaction in transactions {
            if transaction.type == 'expense' {
                category_totals[transaction.category] += transaction.amount
                category_counts[transaction.category]++
            }
        }

        println('💸 Expenses by Category:')
        for category, total in category_totals {
            count := category_counts[category]
            println('  ${category}: \$${total:.2f} (${count} transactions)')
        }

        // Top expenses
        println('\n🏆 Top 5 Expenses:')
        mut expenses := transactions.filter(it.type == 'expense')
        expenses.sort(b.amount > a.amount)

        for i in 0..5 {
            if i < expenses.len {
                expense := expenses[i]
                println('  ${i+1}. ${expense.description}: \$${expense.amount:.2f}')
            }
        }
    }

    println('\nPress Enter to continue...')
    os.get_line()
}

fn search_transactions(transactions []Transaction) {
    print('Search term: ')
    query := os.get_line().trim_space().to_lower()

    clear_screen()
    println('🔍 Search Results for: $query')
    println('-----------------------------')

    mut found := false
    for i, transaction in transactions {
        if transaction.description.to_lower().contains(query) ||
           transaction.category.to_lower().contains(query) ||
           transaction.amount.str().contains(query) {
            symbol := if transaction.type == 'income' { '💰' } else { '💸' }
            amount_str := '\$${transaction.amount:.2f}'
            println('${i+1}. $symbol ${transaction.description} (${transaction.category}) $amount_str')
            found = true
        }
    }

    if !found {
        println('No transactions found matching "$query"')
    }

    println('\nPress Enter to continue...')
    os.get_line()
}

fn delete_transaction(mut transactions []Transaction) {
    list_transactions(transactions)

    if transactions.len == 0 {
        return
    }

    print('\nEnter number of transaction to delete (1-${transactions.len}): ')
    input := os.get_line().trim_space()
    num := input.int()

    if num <= 0 {
        println('\n❌ Please enter a valid transaction number')
        time.sleep(1)
        return
    }

    if num > 0 && num <= transactions.len {
        deleted := transactions[num-1]
        transactions.delete(num-1)
        println('\n🗑️  Deleted: ${deleted.description} (\$${deleted.amount:.2f})')
    } else {
        println('\n❌ Invalid number. Please enter a number between 1 and ${transactions.len}')
    }

    time.sleep(1)
}

fn calculate_total(transactions []Transaction, trans_type string) f64 {
    mut total := 0.0
    for transaction in transactions {
        if transaction.type == trans_type {
            total += transaction.amount
        }
    }
    return total
}

fn load_transactions() []Transaction {
    if !os.exists('transactions.json') {
        return []
    }
    content := os.read_file('transactions.json') or { return [] }
    return json.decode([]Transaction, content) or { [] }
}

fn save_transactions(transactions []Transaction) {
    json_data := json.encode(transactions)
    os.write_file('transactions.json', json_data) or {}
}

fn load_budgets() []Budget {
    if !os.exists('budgets.json') {
        return []
    }
    content := os.read_file('budgets.json') or { return [] }
    return json.decode([]Budget, content) or { [] }
}

fn save_budgets(budgets []Budget) {
    json_data := json.encode(budgets)
    os.write_file('budgets.json', json_data) or {}
}

fn repeat_char(ch string, count int) string {
    mut result := ''
    for _ in 0..count {
        result += ch
    }
    return result
}

fn clear_screen() {
    print('\x1b[2J\x1b[H')
}
