import os
import json
import time
import net
import sync

struct Message {
    id        int
    username  string
    content   string
    timestamp string
    room      string
}

struct User {
    name      string
    mut:
    connected bool
    ip        string
    port      int
}

struct ChatRoom {
    name     string
    mut:
    users    []User
    messages []Message
    mutex    sync.Mutex
}

fn main() {
    clear_screen()
    println('💬 Chat P2P - Terminal Chat Client')
    println('---------------------------------')

    print('Enter your username: ')
    username := os.get_line().trim_space()

    if username == '' {
        println('❌ Username cannot be empty. Exiting...')
        return
    }

    print('Start new room or join existing? (host/join): ')
    choice := os.get_line().trim_space().to_lower()

    match choice {
        'host' {
            start_host(username)
        }
        'join' {
            print('Enter host IP address: ')
            host_ip := os.get_line().trim_space()
            if host_ip == '' {
                println('❌ Host IP cannot be empty. Exiting...')
                return
            }
            join_room(username, host_ip)
        }
        else {
            println('❌ Invalid choice. Use "host" or "join"')
        }
    }
}

fn start_host(username string) {
    port := 8080

    println('🚀 Starting chat room on port $port')
    println('Share your IP address with others to let them join!')
    println('Example: 192.168.1.100 (replace with your actual IP)')
    println('Your local IP: ${get_local_ip()}')

    mut room := ChatRoom{
        name: 'P2P_Chat_${time.now().unix()}',
        users: [User{ name: username, connected: true, ip: get_local_ip(), port: port }],
        messages: [],
        mutex: sync.new_mutex()
    }

    start_server(username, port, mut room)
}

fn join_room(username string, host_ip string) {
    port := 8080

    println('🔗 Attempting to connect to $host_ip:$port')

    mut conn := net.dial_tcp('$host_ip:$port') or {
        println('❌ Failed to connect to host: $err.msg')
        println('Make sure the host is running and the IP address is correct.')
        return
    }

    defer { conn.close() or {} }

    // Send join request
    join_msg := '{\"type\":\"join\",\"username\":\"$username\"}'
    conn.write_string(join_msg) or {}

    start_client(username, host_ip, port, mut conn)
}

fn start_server(username string, port int, mut room ChatRoom) {
    mut server := net.listen(port, 'localhost') or {
        println('❌ Failed to start server: $err.msg')
        return
    }
    defer { server.close() or {} }

    println('✅ Server started successfully!')
    println('Waiting for connections...\n')

    // Start a goroutine to handle the chat interface
    go handle_chat_interface(username, mut room)

    for {
        mut conn := server.accept() or { continue }
        go handle_client(username, mut conn, mut room)
    }
}

fn handle_client(host_username string, mut conn net.TcpConn, mut room ChatRoom) {
    defer { conn.close() or {} }

    // For now, use a simple approach - extract IP from connection string
    client_ip := '192.168.1.100' // Placeholder - in real implementation would extract from conn

    mut buffer := []u8{len: 1024}

    for {
        n := conn.read(mut buffer) or { break }
        if n == 0 { break }

        message_str := buffer[..n].bytestr()

        // Handle join message
        if message_str.contains('join') {
            // Simple parsing for username
            mut start := message_str.index('\"username\":\"') or { continue }
            if start == -1 { continue }
            start += 12 // length of '"username":"'
            mut end := message_str.index_after('\"', start) or { continue }

            join_username := message_str[start..end]

            // Add user to room
            user := User{
                name: join_username,
                connected: true,
                ip: client_ip,
                port: 8080
            }
            room.users << user

            // Send welcome message
            welcome_msg := Message{
                id: room.messages.len + 1,
                username: 'System',
                content: '$join_username joined the chat!',
                timestamp: time.now().format(),
                room: room.name
            }
            room.messages << welcome_msg

            // Broadcast join message to all users
            broadcast_message(welcome_msg, room.users)

            // Send current messages to new user
            for msg in room.messages {
                send_to_peer(client_ip, 8080, msg)
            }
        } else {
            // Process regular message
            process_network_message(message_str, mut room)
        }
    }
}

fn handle_chat_interface(username string, mut room ChatRoom) {
    for {
        print('> ')
        input := os.get_line().trim_space()

        if input == '' {
            continue
        }

        if input.starts_with('/') {
            handle_command(input, username, mut room)
        } else {
            // Broadcast message to all connected clients
            message := Message{
                id: room.messages.len + 1,
                username: username,
                content: input,
                timestamp: time.now().format(),
                room: room.name
            }

            room.messages << message

            broadcast_message(message, room.users)

            display_messages(room.messages, username)
        }
    }
}

fn start_client(username string, host_ip string, port int, mut conn net.TcpConn) {
    clear_screen()
    println('💬 Connected to P2P Chat!')
    println('Connected as: $username')
    println('Host: $host_ip:$port')
    println('Commands: /help, /users, /quit')
    println(repeat_char('-', 35))

    // Start goroutine to receive messages
    go receive_messages(mut conn, username)

    // Chat interface
    for {
        print('> ')
        input := os.get_line().trim_space()

        if input == '' {
            continue
        }

        if input.starts_with('/') {
            if input == '/quit' {
                quit_msg := '{\"type\":\"quit\",\"username\":\"$username\"}'
                conn.write_string(quit_msg) or {}
                println('\n👋 Goodbye!')
                break
            } else if input == '/help' {
                show_help()
            } else if input == '/users' {
                show_users(username)
            } else {
                println('\n❌ Unknown command')
            }
        } else {
            // Send message to host
            msg := '{\"type\":\"message\",\"username\":\"$username\",\"content\":\"$input\"}'
            conn.write_string(msg) or {
                println('❌ Connection lost!')
                break
            }
        }
    }
}

fn receive_messages(mut conn net.TcpConn, username string) {
    mut buffer := []u8{len: 1024}

    for {
        n := conn.read(mut buffer) or { break }
        if n == 0 { break }

        message := buffer[..n].bytestr()
        process_client_message(message, username)
    }
}

fn broadcast_message(message Message, users []User) {
    for user in users {
        if user.connected && user.name != message.username && user.ip != 'unknown' {
            go send_to_peer(user.ip, user.port, message)
        }
    }
}

fn send_to_peer(ip string, port int, message Message) {
    mut conn := net.dial_tcp('$ip:$port') or { return }
    defer { conn.close() or {} }

    msg_json := json.encode(message)
    conn.write_string(msg_json) or {}
}

fn process_network_message(message_str string, mut room ChatRoom) {
    // Parse JSON message
    message := json.decode(Message, message_str) or {
        println('❌ Failed to parse message: $err.msg')
        return
    }

    // Add message to room
    room.messages << message

    // Broadcast to all other users (except sender)
    broadcast_message(message, room.users)
}

fn process_client_message(message_str string, username string) {
    // Parse JSON message
    message := json.decode(Message, message_str) or {
        println('\n❌ Failed to parse message: $err.msg')
        print('> ')
        return
    }

    // Display the message
    if message.username == username {
        println('\n💬 ${message.timestamp} - You: ${message.content}')
    } else {
        println('\n💬 ${message.timestamp} - ${message.username}: ${message.content}')
    }
    print('> ')
}

fn display_messages(messages []Message, current_username string) {
    clear_screen()
    println('💬 Chat P2P')
    println('Connected as: $current_username')
    println('Commands: /help, /users, /quit')
    println(repeat_char('-', 35))

    for message in messages {
        if current_username == 'system' {
            // For system/host display, show all messages normally
            println('💬 ${message.timestamp} - ${message.username}: ${message.content}')
        } else if message.username == current_username {
            println('💬 ${message.timestamp} - You: ${message.content}')
        } else {
            println('💬 ${message.timestamp} - ${message.username}: ${message.content}')
        }
    }

    println('\n💬 You are connected!')
    println('Press Enter to send, Ctrl+C to quit')
}

fn handle_command(command string, username string, mut room ChatRoom) {
    match command {
        '/help' {
            show_help()
        }
        '/users' {
            show_users(username)
        }
        '/quit' {
            println('\n👋 Goodbye, $username!')
            exit(0)
        }
        else {
            println('\n❌ Unknown command: $command')
        }
    }
}

fn show_help() {
    clear_screen()
    println('💬 P2P Chat Commands:')
    println('-------------------')
    println('/help     - Show this help')
    println('/users    - Show connected users')
    println('/quit     - Leave the chat')
    println('\nPress Enter to continue...')
    os.get_line()
}

fn show_users(current_username string) {
    clear_screen()
    println('👥 Connected Users:')
    println('------------------')
    println('• $current_username (you)')

    // In a real implementation, we'd get this from the room data
    // For now, show a placeholder
    println('\nNote: Full user list available in networked version.')
    println('\nPress Enter to continue...')
    os.get_line()
}

fn get_local_ip() string {
    // Simple approach - try to get local IP
    mut conn := net.dial_tcp('8.8.8.8:80') or {
        return '127.0.0.1'
    }
    defer { conn.close() or {} }

    // Get local address (this might not work in current V version)
    // For now, return a placeholder that users can replace
    return '127.0.0.1' // TODO: Implement proper IP detection
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
