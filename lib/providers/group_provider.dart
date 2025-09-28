import 'package:flutter/material.dart';
import '../models/group_model.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';

class GroupProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();

  List<Group> _userGroups = [];
  Group? _selectedGroup;
  List<User> _groupMembers = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Group> get userGroups => _userGroups;
  Group? get selectedGroup => _selectedGroup;
  List<User> get groupMembers => _groupMembers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadUserGroups(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      _userGroups = await _dbService.getUserGroups(userId);
    } catch (e) {
      _errorMessage = 'Failed to load groups: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createGroup(Group group) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _dbService.createGroup(group);
      _userGroups.add(group);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to create group: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> joinGroup(String userId, String inviteCode) async {
    try {
      _isLoading = true;
      notifyListeners();

      final group = await _dbService.getGroupByInviteCode(inviteCode);
      if (group != null) {
        await _dbService.addGroupMember(group.id, userId);
        await loadUserGroups(userId);
        return true;
      }
      _errorMessage = 'Invalid invite code';
      return false;
    } catch (e) {
      _errorMessage = 'Failed to join group: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectGroup(String groupId) async {
    try {
      _isLoading = true;
      notifyListeners();

      _selectedGroup = await _dbService.getGroup(groupId);
      if (_selectedGroup != null) {
        await loadGroupMembers(_selectedGroup!.memberIds);
      }
    } catch (e) {
      _errorMessage = 'Failed to load group details: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadGroupMembers(List<String> memberIds) async {
    try {
      _groupMembers = await _dbService.getUsersByIds(memberIds);
    } catch (e) {
      _errorMessage = 'Failed to load group members: $e';
    }
  }

  Future<bool> addGroupMember(String groupId, String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _dbService.addGroupMember(groupId, userId);
      if (_selectedGroup?.id == groupId) {
        await selectGroup(groupId);
      }
      return true;
    } catch (e) {
      _errorMessage = 'Failed to add member: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> removeGroupMember(String groupId, String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _dbService.removeGroupMember(groupId, userId);
      if (_selectedGroup?.id == groupId) {
        await selectGroup(groupId);
      }
      return true;
    } catch (e) {
      _errorMessage = 'Failed to remove member: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateGroup(Group group) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _dbService.updateGroup(group);

      // Update in local lists
      final index = _userGroups.indexWhere((g) => g.id == group.id);
      if (index != -1) {
        _userGroups[index] = group;
      }

      if (_selectedGroup?.id == group.id) {
        _selectedGroup = group;
      }

      return true;
    } catch (e) {
      _errorMessage = 'Failed to update group: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> leaveGroup(String groupId, String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _dbService.removeGroupMember(groupId, userId);
      _userGroups.removeWhere((g) => g.id == groupId);

      if (_selectedGroup?.id == groupId) {
        _selectedGroup = null;
        _groupMembers = [];
      }

      return true;
    } catch (e) {
      _errorMessage = 'Failed to leave group: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String generateInviteCode() {
    // Generate a random 6-character invite code
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return String.fromCharCodes(Iterable.generate(
        6,
        (_) => chars.codeUnitAt((DateTime.now().millisecondsSinceEpoch *
                DateTime.now().microsecond) %
            chars.length)));
  }

  void clearSelectedGroup() {
    _selectedGroup = null;
    _groupMembers = [];
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
