class AppUser {
  final String username;
  final int journeyCount;
  final DateTime lastLogin;
  final bool isActive;

  AppUser({
    required this.username,
    required this.journeyCount,
    required this.lastLogin,
    required this.isActive,
  });
}