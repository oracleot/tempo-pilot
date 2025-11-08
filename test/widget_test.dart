// Basic Flutter widget test for Tempo Pilot app scaffold.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:tempo_pilot/main.dart';
import 'package:tempo_pilot/providers/auth_provider.dart';

// Mock classes
class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

void main() {
  late MockSupabaseClient mockClient;
  late MockGoTrueClient mockAuth;

  setUp(() {
    mockClient = MockSupabaseClient();
    mockAuth = MockGoTrueClient();

    when(() => mockClient.auth).thenReturn(mockAuth);
    when(() => mockAuth.currentSession).thenReturn(null);
    when(
      () => mockAuth.onAuthStateChange,
    ).thenAnswer((_) => const Stream.empty());
  });

  testWidgets('App launches with login page', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [supabaseClientProvider.overrideWithValue(mockClient)],
        child: const TempoPilotApp(),
      ),
    );

    // Verify that the app launches and shows login screen.
    expect(find.text('Welcome to Tempo Pilot'), findsOneWidget);
    expect(find.text('Send Magic Link'), findsOneWidget);
  });
}
