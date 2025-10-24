import os
import time

fn main() {
    mut current_dir := os.getwd()

    for {
        clear_screen()
        println('📁 Browse - Navigate Your Filesystem')
        println('------------------------------------')
        println('Current: $current_dir')
        println('')

        // List files and directories
        items := os.ls(current_dir) or {
            println('❌ Error reading directory')
            continue
        }

        mut directories := []string{}
        mut files := []string{}

        for item in items {
            full_path := os.join_path(current_dir, item)
            if os.is_dir(full_path) {
                directories << item
            } else {
                files << item
            }
        }

        // Show directories first
        if directories.len > 0 {
            println('📂 Directories:')
            for i, dir in directories {
                println('  ${i+1}. 📁 $dir')
            }
        }

        // Show files
        if files.len > 0 {
            println('\n📄 Files:')
            for i, file in files {
                full_path := os.join_path(current_dir, file)
                size := os.file_size(full_path)
                size_str := format_size(size)
                println('  ${i+directories.len+1}. 📄 $file (${size_str})')
            }
        }

        println('\nCommands: cd <num/name>, back, info <num>, quit')
        print('> ')
        input := os.get_line().trim_space()

        if input == 'quit' {
            println('\n👋 Happy browsing! Goodbye!')
            break
        } else if input == 'back' {
            parent := os.dir(current_dir)
            if parent != current_dir {
                current_dir = parent
            } else {
                println('\n❌ Already at root directory')
                time.sleep(1)
            }
        } else if input.starts_with('cd ') {
            target := input[3..].trim_space()
            handle_cd_command(target, current_dir, directories, files)
            current_dir = os.getwd()
        } else if input.starts_with('info ') {
            num_str := input[5..].trim_space()
            num := num_str.int()
            show_file_info(num, directories, files, current_dir)
        }
    }
}

fn handle_cd_command(target string, current_dir string, directories []string, files []string) {
    // Try to find by number first
    if is_numeric(target) {
        num := target.int()
        // Check directories first
        if num > 0 && num <= directories.len {
            item := directories[num-1]
            full_path := os.join_path(current_dir, item)
            if os.is_dir(full_path) {
                os.chdir(full_path) or {
                    println('\n❌ Cannot access directory: $item')
                    time.sleep(1)
                    return
                }
            } else {
                println('\n❌ Not a directory: $item')
                time.sleep(1)
            }
        } else {
            // Check files (adjusting for directory offset)
            file_num := num - directories.len
            if file_num > 0 && file_num <= files.len {
                item := files[file_num-1]
                println('\n❌ Not a directory: $item')
                time.sleep(1)
            } else {
                println('\n❌ Invalid number')
                time.sleep(1)
            }
        }
    } else {
        // Try by name
        full_path := os.join_path(current_dir, target)
        if os.is_dir(full_path) {
            os.chdir(full_path) or {
                println('\n❌ Cannot access directory: $target')
                time.sleep(1)
                return
            }
        } else {
            println('\n❌ Directory not found: $target')
            time.sleep(1)
        }
    }
}

fn show_file_info(num int, directories []string, files []string, current_dir string) {
    // Check directories first
    if num > 0 && num <= directories.len {
        item := directories[num-1]
        full_path := os.join_path(current_dir, item)

        clear_screen()
        println('📋 File Information')
        println('-------------------')
        println('Name: $item')
        println('Path: $full_path')
        println('Type: Directory')

        item_count := os.ls(full_path) or { []string{} }
        println('Items: ${item_count.len}')
    } else {
        // Check files (adjusting for directory offset)
        file_num := num - directories.len
        if file_num > 0 && file_num <= files.len {
            item := files[file_num-1]
            full_path := os.join_path(current_dir, item)

            clear_screen()
            println('📋 File Information')
            println('-------------------')
            println('Name: $item')
            println('Path: $full_path')
            println('Type: File')

            size := os.file_size(full_path)
            println('Size: ${format_size(size)}')
            println('Size (bytes): $size')
        } else {
            println('\n❌ Invalid number')
            time.sleep(1)
            return
        }
    }

    println('\nPress Enter to continue...')
    os.get_line()
}

fn format_size(bytes i64) string {
    if bytes < 1024 {
        return '${bytes} B'
    } else if bytes < 1024 * 1024 {
        return '${bytes/1024} KB'
    } else if bytes < 1024 * 1024 * 1024 {
        return '${bytes/(1024*1024)} MB'
    } else {
        return '${bytes/(1024*1024*1024)} GB'
    }
}

fn is_numeric(s string) bool {
    if s.len == 0 {
        return false
    }
    for c in s {
        if !c.is_digit() && c != `.` {
            return false
        }
    }
    return true
}

fn clear_screen() {
    print('\x1b[2J\x1b[H')
}
