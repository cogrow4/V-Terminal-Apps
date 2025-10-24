import os
import rand
import time

struct Question {
    question string
    options  []string
    answer   int
    explanation string
}

struct Quiz {
    name        string
    questions   []Question
    difficulty  string
}

fn main() {
    clear_screen()
    println('🎯 Quiz - Test Your Knowledge!')
    println('-----------------------------')

    // Sample quizzes
    quizzes := [
        Quiz{
            name: 'General Knowledge',
            difficulty: 'Easy',
            questions: [
                Question{'What is the capital of France?', ['London', 'Berlin', 'Paris', 'Madrid'], 3, 'Paris is the capital and largest city of France.'},
                Question{'Which planet is known as the Red Planet?', ['Venus', 'Mars', 'Jupiter', 'Saturn'], 2, 'Mars appears red due to iron oxide on its surface.'},
                Question{'What is 2 + 2?', ['3', '4', '5', '6'], 2, 'Basic arithmetic: 2 + 2 equals 4.'},
                Question{'Who painted the Mona Lisa?', ['Van Gogh', 'Picasso', 'Da Vinci', 'Michelangelo'], 3, 'Leonardo da Vinci painted the Mona Lisa between 1503 and 1519.'},
                Question{'What is the largest ocean on Earth?', ['Atlantic', 'Indian', 'Arctic', 'Pacific'], 4, 'The Pacific Ocean covers about 46% of the world\'s water surface.'}
            ]
        },
        Quiz{
            name: 'Science & Technology',
            difficulty: 'Medium',
            questions: [
                Question{'What does "HTTP" stand for?', ['HyperText Transfer Protocol', 'High Tech Transfer Protocol', 'HyperText Technical Protocol', 'High Transfer Text Protocol'], 1, 'HTTP is the foundation of data communication on the World Wide Web.'},
                Question{'Which gas makes up about 78% of Earth\'s atmosphere?', ['Oxygen', 'Carbon Dioxide', 'Nitrogen', 'Hydrogen'], 3, 'Nitrogen is the most abundant gas in Earth\'s atmosphere.'},
                Question{'What is the chemical symbol for gold?', ['Go', 'Gd', 'Au', 'Ag'], 3, 'Au comes from the Latin word "aurum" meaning gold.'},
                Question{'Which programming language is known as "Write Once, Run Anywhere"?', ['Python', 'Java', 'C++', 'JavaScript'], 2, 'Java\'s WORA capability is achieved through the Java Virtual Machine.'},
                Question{'What is the speed of light in vacuum?', ['299,792,458 m/s', '300,000,000 m/s', '186,000 miles/s', 'All of the above'], 4, 'The speed of light in vacuum is approximately 299,792,458 meters per second.'}
            ]
        },
        Quiz{
            name: 'Programming',
            difficulty: 'Hard',
            questions: [
                Question{'Which of the following is NOT a primitive data type in most programming languages?', ['int', 'string', 'boolean', 'function'], 4, 'Function is a complex type, not a primitive data type.'},
                Question{'What does "API" stand for in programming?', ['Application Programming Interface', 'Advanced Programming Interface', 'Application Process Integration', 'Automated Program Integration'], 1, 'APIs allow different software applications to communicate with each other.'},
                Question{'Which sorting algorithm has the worst-case time complexity of O(n²)?', ['Merge Sort', 'Quick Sort', 'Bubble Sort', 'Binary Search'], 3, 'Bubble Sort has O(n²) time complexity in the worst case.'},
                Question{'What is "Big O" notation used for?', ['Measuring algorithm efficiency', 'Counting lines of code', 'Memory management', 'File organization'], 1, 'Big O notation describes the performance or complexity of an algorithm.'},
                Question{'Which HTTP status code means "Not Found"?', ['200', '301', '404', '500'], 3, '404 is the standard response for a resource that cannot be found.'}
            ]
        }
    ]

    // Show available quizzes
    println('\nAvailable Quizzes:')
    for i, quiz in quizzes {
        println('${i+1}. ${quiz.name} (${quiz.difficulty}) - ${quiz.questions.len} questions')
    }

    print('\nSelect a quiz (1-${quizzes.len}) or "random": ')
    choice := os.get_line().trim_space()

    mut selected_quiz := Quiz{}
    if choice.to_lower() == 'random' {
        selected_quiz = quizzes[rand.intn(quizzes.len) or { 0 }]
    } else {
        quiz_num := choice.int()
        if quiz_num > 0 && quiz_num <= quizzes.len {
            selected_quiz = quizzes[quiz_num-1]
        } else {
            println('❌ Invalid choice. Please select a number between 1 and ${quizzes.len}, or type "random"')
            println('\nPress Enter to exit...')
            os.get_line()
            return
        }
    }

    // Run the quiz
    run_quiz(selected_quiz)
}

fn run_quiz(quiz Quiz) {
    clear_screen()
    println('🎯 Starting: ${quiz.name} (${quiz.difficulty})')
    println(repeat_char('=', quiz.name.len + 15))
    println('Answer by typing the number of your choice.\n')

    mut score := 0
    mut total_time := i64(0)

    for i, question in quiz.questions {
        start_time := time.now().unix()

        clear_screen()
        println('Question ${i+1}/${quiz.questions.len}')
        println('Score: $score/${i}')
        println(repeat_char('-', 20))
        println('${question.question}\n')

        for j, option in question.options {
            println('${j+1}. $option')
        }

        print('\nYour answer (1-${question.options.len}): ')
        answer_str := os.get_line().trim_space()
        end_time := time.now().unix()

        question_time := end_time - start_time
        total_time += question_time

        answer := answer_str.int()
        if answer <= 0 || answer > question.options.len {
            println('\n❌ Invalid answer. Please enter a number between 1 and ${question.options.len} (+${question_time}s)')
            println('The correct answer was ${question.answer}.')
            if question.explanation != '' {
                println('💡 ${question.explanation}')
            }
        } else if answer == question.answer {
            score++
            println('\n✅ Correct! (+${question_time}s)')
            if question.explanation != '' {
                println('💡 ${question.explanation}')
            }
        } else {
            println('\n❌ Wrong! The correct answer was ${question.answer}. (+${question_time}s)')
            if question.explanation != '' {
                println('💡 ${question.explanation}')
            }
        }

        if i < quiz.questions.len - 1 {
            println('\nPress Enter for next question...')
            os.get_line()
        }
    }

    // Show final results
    clear_screen()
    println('🎉 Quiz Complete!')
    println(repeat_char('=', 17))
    println('${quiz.name} (${quiz.difficulty})')
    println('\n📊 Results:')
    println('- Final Score: $score/${quiz.questions.len}')
    println('- Percentage: ${f64(score) / f64(quiz.questions.len) * 100:.1f}%')
    println('- Total Time: ${total_time}s')
    println('- Average Time: ${f64(total_time) / f64(quiz.questions.len):.1f}s per question')

    if score == quiz.questions.len {
        println('\n🏆 Perfect Score! You\'re a genius!')
    } else if f64(score) / f64(quiz.questions.len) >= 0.8 {
        println('\n🌟 Excellent work!')
    } else if f64(score) / f64(quiz.questions.len) >= 0.6 {
        println('\n👍 Good job!')
    } else {
        println('\n📚 Keep studying!')
    }

    println('\nPress Enter to exit...')
    os.get_line()
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
