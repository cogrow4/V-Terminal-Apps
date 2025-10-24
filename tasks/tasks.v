import os
import json
import time

struct Task {
    id        int
    mut:
    content   string
    completed bool
    created_at string
}

fn main() {
    mut tasks := load_tasks()
    
    for {
        clear_screen()
        println('📝 Tasks - Your Terminal Task Manager')
        println('-----------------------------------')
        
        if tasks.len == 0 {
            println('No tasks yet. Add one below!\n')
        } else {
            for i, task in tasks {
                status := if task.completed { '✅' } else { '⬜' }
                println('${i+1}. $status ${task.content}')
            }
            println('')
        }
        
        println('\nCommands: add <task>, complete <num>, delete <num>, quit')
        print('> ')
        input := os.get_line().trim_space()
        
        if input == 'quit' {
            save_tasks(tasks)
            println('\n👋 Tasks saved. Goodbye!')
            break
        } else if input.starts_with('add ') {
            task_content := input[4..].trim_space()
            if task_content != '' {
                new_task := Task{
                    id: if tasks.len > 0 { tasks.last().id + 1 } else { 1 },
                    content: task_content,
                    completed: false,
                    created_at: time.now().format()
                }
                tasks << new_task
                println('\n✅ Task added!')
                time.sleep(1)
            }
        } else if input.starts_with('complete ') {
            num_str := input[9..].trim_space()
            num := num_str.int()
            if num <= 0 {
                println('\n❌ Please enter a valid task number')
                time.sleep(1)
                continue
            }
            if num > 0 && num <= tasks.len {
                tasks[num-1].completed = !tasks[num-1].completed
                status := if tasks[num-1].completed { 'completed' } else { 'marked as incomplete' }
                println('\n✅ Task $num $status')
                time.sleep(1)
            } else {
                println('\n❌ Invalid task number')
                time.sleep(1)
            }
        } else if input.starts_with('delete ') {
            num_str := input[7..].trim_space()
            num := num_str.int()
            if num <= 0 {
                println('\n❌ Please enter a valid task number')
                time.sleep(1)
                continue
            }
            if num > 0 && num <= tasks.len {
                tasks.delete(num-1)
                println('\n🗑️  Task $num deleted')
                time.sleep(1)
            } else {
                println('\n❌ Invalid task number')
                time.sleep(1)
            }
        }
    }
}

fn load_tasks() []Task {
    if !os.exists('tasks.json') {
        return []
    }
    content := os.read_file('tasks.json') or { return [] }
    return json.decode([]Task, content) or { [] }
}

fn save_tasks(tasks []Task) {
    json_data := json.encode(tasks)
    os.write_file('tasks.json', json_data) or {}
}

fn clear_screen() {
    print('\x1b[2J\x1b[H')
}
