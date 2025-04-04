import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:chiw_express/auth_provider.dart'; // Correct package import

class DeepLinkHandler extends StatefulWidget {
  final Widget child;
  const DeepLinkHandler({required this.child, super.key});

  @override
  State<DeepLinkHandler> createState() => _DeepLinkHandlerState();
}

class _DeepLinkHandlerState extends State<DeepLinkHandler> {
  StreamSubscription? _sub;
  final _appLinks = AppLinks();

  @override
  void initState() {
    super.initState();
    _initDeepLinkListener();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _initDeepLinkListener() async {
    try {
      final initialLink = await _appLinks.getInitialLinkString();
      if (initialLink != null && mounted) {
        _handleDeepLink(initialLink);
      }
    } catch (e) {
      debugPrint('Error getting initial link: $e');
    }

    _sub = _appLinks.stringLinkStream.listen((String? link) {
      if (link != null && mounted) {
        _handleDeepLink(link);
      }
    }, onError: (err) {
      debugPrint('Error listening to deep links: $err');
    });
  }

  void _handleDeepLink(String link) {
    final uri = Uri.parse(link);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    String? status = uri.queryParameters['status'];
    String? txRef = uri.queryParameters['tx_ref'];
    String? transactionId = uri.queryParameters['transaction_id'];
    String? message = uri.queryParameters['message'];
    String? groceryId = uri.queryParameters['grocery_id'];

    debugPrint('Deep link received: $link');

    String snackBarMessage;
    Color snackBarColor;
    String? navigateTo;
    Map<String, dynamic>? arguments;

    if (uri.scheme == 'canibuyyouamealexpress') {
      if (uri.host == 'payment-callback') {
        switch (status) {
          case 'success':
            snackBarMessage = 'Restaurant order payment successful!';
            snackBarColor = Colors.green;
            authProvider.refreshOrders();
            navigateTo = '/orders';
            arguments = {'orderId': txRef, 'status': 'success'};
            break;
          case 'cancelled':
            snackBarMessage = 'Restaurant order payment was cancelled.';
            snackBarColor = Colors.orange;
            navigateTo = '/orders';
            arguments = {'orderId': txRef, 'status': 'cancelled'};
            break;
          case 'failed':
            snackBarMessage = 'Restaurant order payment failed.';
            snackBarColor = Colors.red;
            navigateTo = '/orders';
            arguments = {'orderId': txRef, 'status': 'failed'};
            break;
          case 'error':
            snackBarMessage = message ?? 'An error occurred with your order.';
            snackBarColor = Colors.red;
            navigateTo = '/home';
            break;
          default:
            snackBarMessage = 'Unknown payment status.';
            snackBarColor = Colors.grey;
            navigateTo = '/home';
        }
      } else if (uri.host == 'groceries') {
        switch (status) {
          case 'success':
            snackBarMessage = 'Grocery order payment successful!';
            snackBarColor = Colors.green;
            authProvider.refreshGroceries();
            navigateTo = '/groceries';
            arguments = {'groceryId': groceryId ?? txRef, 'status': 'success'};
            break;
          case 'cancelled':
            snackBarMessage = 'Grocery order payment was cancelled.';
            snackBarColor = Colors.orange;
            navigateTo = '/groceries';
            arguments = {
              'groceryId': groceryId ?? txRef,
              'status': 'cancelled'
            };
            break;
          case 'failed':
            snackBarMessage = 'Grocery order payment failed.';
            snackBarColor = Colors.red;
            navigateTo = '/groceries';
            arguments = {'groceryId': groceryId ?? txRef, 'status': 'failed'};
            break;
          case 'error':
            snackBarMessage =
                message ?? 'An error occurred with your grocery order.';
            snackBarColor = Colors.red;
            navigateTo = '/home';
            break;
          default:
            snackBarMessage = 'Unknown payment status.';
            snackBarColor = Colors.grey;
            navigateTo = '/home';
        }
      } else {
        snackBarMessage = 'Invalid deep link host.';
        snackBarColor = Colors.red;
        navigateTo = '/home';
      }
    } else {
      snackBarMessage = 'Invalid deep link scheme.';
      snackBarColor = Colors.red;
      navigateTo = '/home';
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(snackBarMessage),
          backgroundColor: snackBarColor,
          duration: const Duration(seconds: 3),
        ),
      );

      if (navigateTo != null) {
        Navigator.pushReplacementNamed(
          context,
          navigateTo,
          arguments: arguments,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
