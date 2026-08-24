import 'dart:html' as html;

void clearAuthCallbackUrl() {
  html.window.history.replaceState(null, html.document.title, '/#/home');
}