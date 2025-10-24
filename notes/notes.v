import os
import json
import time

struct Note {
    id        int
    mut:
    title     string
    content   string
    created_at string
    updated_at string
}

fn main() {
    mut notes := load_notes()
    
    for {
        clear_screen()
        println('📓 Notes - Your Terminal Note-Taking App')
        println('---------------------------------------')
        
        if notes.len == 0 {
            println('No notes yet. Create one below!\n')
        } else {
            for i, note in notes {
                preview := if note.content.len > 30 { note.content[..30] + '...' } else { note.content }
                println('${i+1}. ${note.title} - $preview')
            }
            println('')
        }
        
        println('\nCommands: new, view <num>, edit <num>, delete <num>, search <query>, quit')
        print('> ')
        input := os.get_line().trim_space()
        
        if input == 'quit' {
            save_notes(notes)
            println('\n👋 Notes saved. Goodbye!')
            break
        } else if input == 'new' {
            print('Title: ')
            title := os.get_line().trim_space()
            if title == '' {
                println('\n❌ Title cannot be empty')
                time.sleep(1)
                continue
            }
            
            println('Content (Press Enter twice on empty lines to save, or type "EOF" to finish):')
            mut content := ''
            mut line_count := 0
            for {
                line := os.get_line()
                if line == 'EOF' || (line == '' && line_count > 0) {
                    break
                }
                if line == '' {
                    line_count++
                } else {
                    line_count = 0
                }
                content += line + '\n'
            }
            
            new_note := Note{
                id: if notes.len > 0 { notes.last().id + 1 } else { 1 },
                title: title,
                content: content.trim_space(),
                created_at: time.now().format(),
                updated_at: time.now().format()
            }
            notes << new_note
            println('\n✅ Note created!')
            time.sleep(1)
            
        } else if input.starts_with('view ') {
            num_str := input[5..].trim_space()
            num := num_str.int()
            if num <= 0 {
                println('\n❌ Please enter a valid note number')
                time.sleep(1)
                continue
            }
            if num > 0 && num <= notes.len {
                clear_screen()
                note := notes[num-1]
                println('📝 ${note.title}')
                println(repeat_char('-', note.title.len + 2))
                println(note.content)
                println('\nCreated: ${note.created_at}')
                println('Updated: ${note.updated_at}')
                println('\nPress Enter to continue...')
                os.get_line()
            } else {
                println('\n❌ Invalid note number. Please enter a number between 1 and ${notes.len}')
                time.sleep(1)
            }
        } else if input.starts_with('edit ') {
            num_str := input[5..].trim_space()
            num := num_str.int()
            if num <= 0 {
                println('\n❌ Please enter a valid note number')
                time.sleep(1)
                continue
            }
            if num > 0 && num <= notes.len {
                print('New title (leave empty to keep "${notes[num-1].title}"): ')
                new_title := os.get_line().trim_space()
                if new_title != '' {
                    notes[num-1].title = new_title
                }

                println('Current content (Type new content or press Enter to keep current):')
                println('---')
                println(notes[num-1].content)
                println('---')
                println('Enter new content (press Enter twice on empty line to save):')

                mut new_content := ''
                mut content_line_count := 0
                for {
                    line := os.get_line()
                    if line == '' && content_line_count > 0 {
                        break
                    }
                    if line == '' {
                        content_line_count++
                    } else {
                        content_line_count = 0
                    }
                    new_content += line + '\n'
                }

                if new_content.trim_space() != '' {
                    notes[num-1].content = new_content.trim_space()
                }

                notes[num-1].updated_at = time.now().format()
                println('\n✅ Note updated!')
                time.sleep(1)
            } else {
                println('\n❌ Invalid note number. Please enter a number between 1 and ${notes.len}')
                time.sleep(1)
            }
        } else if input.starts_with('delete ') {
            num_str := input[7..].trim_space()
            num := num_str.int()
            if num <= 0 {
                println('\n❌ Please enter a valid note number')
                time.sleep(1)
                continue
            }
            if num > 0 && num <= notes.len {
                notes.delete(num-1)
                println('\n🗑️  Note $num deleted')
                time.sleep(1)
            } else {
                println('\n❌ Invalid note number. Please enter a number between 1 and ${notes.len}')
                time.sleep(1)
            }
        } else if input.starts_with('search ') {
            query := input[7..].trim_space().to_lower()
            clear_screen()
            println('🔍 Search results for: $query')
            println('------------------------')
            
            mut found := false
            for i, note in notes {
                if note.title.to_lower().contains(query) || note.content.to_lower().contains(query) {
                    preview := if note.content.len > 50 { note.content[..50] + '...' } else { note.content }
                    println('${i+1}. ${note.title} - $preview')
                    found = true
                }
            }
            
            if !found {
                println('No matching notes found.')
            }
            
            println('\nPress Enter to continue...')
            os.get_line()
        }
    }
}

fn load_notes() []Note {
    if !os.exists('notes.json') {
        return []
    }
    content := os.read_file('notes.json') or { return [] }
    return json.decode([]Note, content) or { [] }
}

fn save_notes(notes []Note) {
    json_data := json.encode(notes)
    os.write_file('notes.json', json_data) or {}
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
