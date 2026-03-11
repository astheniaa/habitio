import '../models/entities/user.dart';

abstract class UserRepository {
  Future<User> getOrCreateDefaultUser();
  Future<void> updateUser(User user);
}
