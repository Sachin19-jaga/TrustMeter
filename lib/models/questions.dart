class ExamQuestion {
  final int number;
  final String question;
  final List<String> options;
  final int correctIndex;

  const ExamQuestion({
    required this.number,
    required this.question,
    required this.options,
    required this.correctIndex,
  });
}

// Sample exam questions — replace with your real questions
const List<ExamQuestion> examQuestions = [
  ExamQuestion(
    number: 1,
    question: 'What is the time complexity of binary search?',
    options: ['O(n)', 'O(log n)', 'O(n²)', 'O(1)'],
    correctIndex: 1,
  ),
  ExamQuestion(
    number: 2,
    question: 'Which data structure uses LIFO principle?',
    options: ['Queue', 'Array', 'Stack', 'LinkedList'],
    correctIndex: 2,
  ),
  ExamQuestion(
    number: 3,
    question: 'What does CPU stand for?',
    options: [
      'Central Processing Unit',
      'Computer Personal Unit',
      'Central Program Utility',
      'Core Processing Unit'
    ],
    correctIndex: 0,
  ),
  ExamQuestion(
    number: 4,
    question: 'Which protocol is used to send emails?',
    options: ['HTTP', 'FTP', 'SMTP', 'TCP'],
    correctIndex: 2,
  ),
  ExamQuestion(
    number: 5,
    question: 'What is the output of 2³ in binary?',
    options: ['0110', '1000', '0111', '1010'],
    correctIndex: 1,
  ),
  ExamQuestion(
    number: 6,
    question: 'Which layer of OSI model handles routing?',
    options: ['Physical', 'Data Link', 'Network', 'Transport'],
    correctIndex: 2,
  ),
  ExamQuestion(
    number: 7,
    question: 'What is a primary key in a database?',
    options: [
      'A key used to encrypt data',
      'A unique identifier for each record',
      'The first column in a table',
      'A foreign key reference'
    ],
    correctIndex: 1,
  ),
  ExamQuestion(
    number: 8,
    question: 'Which sorting algorithm has best average case O(n log n)?',
    options: ['Bubble Sort', 'Insertion Sort', 'Merge Sort', 'Selection Sort'],
    correctIndex: 2,
  ),
  ExamQuestion(
    number: 9,
    question: 'What does RAM stand for?',
    options: [
      'Read Access Memory',
      'Random Access Memory',
      'Rapid Access Module',
      'Read And Modify'
    ],
    correctIndex: 1,
  ),
  ExamQuestion(
    number: 10,
    question: 'Which HTML tag is used to create a hyperlink?',
    options: ['<link>', '<href>', '<a>', '<url>'],
    correctIndex: 2,
  ),
];
