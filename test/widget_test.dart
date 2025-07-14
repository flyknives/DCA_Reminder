import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:btc_dca_reminder/providers/btc_provider.dart';
import 'package:btc_dca_reminder/providers/kline_chart_provider.dart';
import 'package:btc_dca_reminder/screens/home_screen.dart';

void main() {
  testWidgets('HomeScreen renders correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => BtcProvider()),
          ChangeNotifierProvider(create: (_) => KlineChartProvider()),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    // Verify that the title is displayed.
    expect(find.text('BTC DCA 提醒'), findsOneWidget);
  });
}
