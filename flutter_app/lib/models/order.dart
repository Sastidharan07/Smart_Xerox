class Order {
  final int orderId;      // Matches your backend JSON: id / orderId
  final List<String> fileNames;
  final String status;
  final String bin;
  final String paymentMethod;
  final String lunchTime;
  final int pages;
  final int copies;
  final String printType;
  final String sides;
  final int amount;

  Order({
    required this.orderId,
    required this.fileNames,
    required this.status,
    required this.bin,
    required this.paymentMethod,
    required this.lunchTime,
    required this.pages,
    required this.copies,
    required this.printType,
    required this.sides,
    required this.amount,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      orderId: json['id'] ?? 0,               // <-- SQLite uses 'id' in JSON
      fileNames: (json['filePath'] as String?)?.split(',').map((path) => path.split('/').last).toList() ?? [],
      status: json['status'] ?? '',
      bin: json['bin'] ?? '',
      paymentMethod: json['paymentMethod'] ?? '',
      lunchTime: json['lunchTime'] ?? '',
      pages: json['pages'] ?? 0,
      copies: json['copies'] ?? 0,
      printType: json['printType'] ?? '',
      sides: json['sides'] ?? '',
      amount: json['amount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': orderId,
      'filePath': fileNames.join(','),
      'status': status,
      'bin': bin,
      'paymentMethod': paymentMethod,
      'lunchTime': lunchTime,
      'pages': pages,
      'copies': copies,
      'printType': printType,
      'sides': sides,
      'amount': amount,
    };
  }
}
