import os
import time

struct PomodoroSettings {
    work_minutes    int
    short_break_min int
    long_break_min  int
    sessions_until_long int
}

struct Session {
    session_type string // "work", "short_break", "long_break"
    start_time   i64
    duration     int
}

fn main() {
    clear_screen()
    println('⏰ Pom - Focus & Productivity Timer')
    println('----------------------------------')

    print('Work session (minutes) [25]: ')
    work_min_str := os.get_line().trim_space()
    work_min := if work_min_str == '' { 25 } else { work_min_str.int() }

    print('Short break (minutes) [5]: ')
    short_break_str := os.get_line().trim_space()
    short_break := if short_break_str == '' { 5 } else { short_break_str.int() }

    print('Long break (minutes) [15]: ')
    long_break_str := os.get_line().trim_space()
    long_break := if long_break_str == '' { 15 } else { long_break_str.int() }

    print('Sessions until long break [4]: ')
    sessions_str := os.get_line().trim_space()
    sessions_until_long := if sessions_str == '' { 4 } else { sessions_str.int() }

    settings := PomodoroSettings{
        work_minutes: work_min,
        short_break_min: short_break,
        long_break_min: long_break,
        sessions_until_long: sessions_until_long
    }

    println('\n🍅 Starting Pomodoro Timer...')
    println('Settings: $work_min min work, $short_break min short break, $long_break min long break')
    println('Long break every $sessions_until_long sessions')
    println('\nPress Enter to start, Ctrl+C to quit anytime...')
    os.get_line()

    run_pomodoro(settings)
}

fn run_pomodoro(settings PomodoroSettings) {
    mut session_count := 0
    mut total_sessions := 0

    for {
        session_count++
        total_sessions++

        // Determine session type
        session_type := if session_count > settings.sessions_until_long {
            'long_break'
        } else if session_count % settings.sessions_until_long == 0 {
            'long_break'
        } else if session_count % 2 == 1 {
            'work'
        } else {
            'short_break'
        }

        // Get duration based on session type
        duration := match session_type {
            'work' { settings.work_minutes }
            'short_break' { settings.short_break_min }
            'long_break' { settings.long_break_min }
            else { settings.work_minutes }
        }

        run_session(session_type, duration, total_sessions)

        // Reset session count after long break
        if session_type == 'long_break' {
            session_count = 0
        }

        // Check if user wants to continue
        if session_type == 'long_break' {
            clear_screen()
            println('🎉 Long break complete!')
            println('Total sessions completed: $total_sessions')
            println('\nContinue with more sessions? (y/n): ')
            continue_input := os.get_line().trim_space().to_lower()

            if continue_input != 'y' && continue_input != 'yes' {
                println('\n👋 Great work! Keep up the productivity!')
                break
            }
        }
    }
}

fn run_session(session_type string, minutes int, session_num int) {
    clear_screen()

    session_name := match session_type {
        'work' { '🍅 Work Session' }
        'short_break' { '☕ Short Break' }
        'long_break' { '🏖️  Long Break' }
        else { 'Unknown Session' }
    }

    println('$session_name #${session_num}')
    println(repeat_char('-', session_name.len + 3))
    println('Duration: ${minutes} minutes')
    println('\nPress Enter to start...')
    os.get_line()

    start_time := time.now().unix()
    end_time := start_time + (minutes * 60)

    for {
        current_time := time.now().unix()
        remaining_seconds := end_time - current_time

        if remaining_seconds <= 0 {
            break
        }

        clear_screen()
        remaining_min := remaining_seconds / 60
        remaining_sec := remaining_seconds % 60

        progress_bar := create_progress_bar(int(remaining_seconds), minutes * 60, 20)

        println('$session_name #${session_num}')
        println('Time remaining: ${remaining_min:02d}:${remaining_sec:02d}')
        println('Progress: [$progress_bar]')
        println('\nPress Ctrl+C to cancel...')

        time.sleep(1)
    }

    // Session complete notification
    clear_screen()
    println('🔔 $session_name Complete!')
    println(repeat_char('=', session_name.len + 9))

    if session_type == 'work' {
        println('💪 Great work! Take a well-deserved break.')
        println('\nFocus tips for next session:')
        tips := [
            '💧 Stay hydrated',
            '📝 Review your goals',
            '🧘‍♀️ Take deep breaths',
            '🎯 Set clear objectives'
        ]
        println(tips[session_num % tips.len])
    } else if session_type == 'short_break' {
        println('☕ Break time over! Ready for more focused work?')
    } else {
        println('🏖️  Long break complete! You\'ve earned this rest.')
        println('Total sessions completed: ${session_num}')
    }

    // Desktop notification (if possible)
    notify_session_complete(session_type, session_num)

    println('\nPress Enter to continue...')
    os.get_line()
}

fn create_progress_bar(remaining int, total int, width int) string {
    if total <= 0 {
        return repeat_char('░', width)
    }

    completed := total - remaining
    percentage := f64(completed) / f64(total)
    filled := int(percentage * f64(width))

    mut bar := ''
    for i in 0..width {
        if i < filled {
            bar += '█'
        } else {
            bar += '░'
        }
    }

    return bar
}

fn notify_session_complete(session_type string, session_num int) {
    // Try to send a desktop notification
    message := match session_type {
        'work' { 'Work session complete! Time for a break.' }
        'short_break' { 'Break over! Back to work.' }
        'long_break' { 'Long break complete! Ready for more sessions?' }
        else { 'Session complete!' }
    }

    // Try different notification methods (without error handling since os.system doesn't return Result)
    os.system('notify-send "Pom" "$message"')
    // Fallback: just print to console if notification fails
    // os.system('echo "$message"')
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
