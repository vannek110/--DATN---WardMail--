// Đây là một bài kiểm tra widget cơ bản của Flutter.
// Để thực hiện tương tác với một widget trong bài kiểm tra của bạn, hãy sử dụng tiện ích WidgetTester
// trong gói flutter_test. Ví dụ: bạn có thể gửi các cử chỉ chạm và cuộn.
// Bạn cũng có thể sử dụng WidgetTester để tìm các widget con trong cây widget,
// đọc văn bản và xác minh rằng các giá trị của thuộc tính widget là chính xác.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App renders a simple test widget', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: Text('Test widget'))),
      ),
    );

    expect(find.text('Test widget'), findsOneWidget);
  });
}
