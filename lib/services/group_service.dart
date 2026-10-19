import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GroupSummary {
  final String id;
  final String name;
  final String currencyCode;
  final String inviteCode;
  final String creatorId;

  const GroupSummary({
    required this.id,
    required this.name,
    required this.currencyCode,
    required this.inviteCode,
    required this.creatorId,
  });

  factory GroupSummary.fromMap(
    String id,
    Map<String, dynamic> data, {
    required String creatorId,
  }) {
    return GroupSummary(
      id: id,
      name: data['name'] as String,
      currencyCode: data['currencyCode'] as String,
      inviteCode: data['inviteCode'] as String,
      creatorId: creatorId,
    );
  }
}

class GroupMember {
  final String id;
  final String name;
  final double contribution;

  const GroupMember({
    required this.id,
    required this.name,
    required this.contribution,
  });

  factory GroupMember.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    return GroupMember(
      id: document.id,
      name: data['name'] as String,
      contribution: (data['contribution'] as num).toDouble(),
    );
  }
}

class GroupExpense {
  final String id;
  final String title;
  final String category;
  final String paidByName;
  final double amount;
  final DateTime date;

  const GroupExpense({
    required this.id,
    required this.title,
    required this.category,
    required this.paidByName,
    required this.amount,
    required this.date,
  });

  factory GroupExpense.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final timestamp = data['createdAt'] as Timestamp?;
    return GroupExpense(
      id: document.id,
      title: data['title'] as String,
      category: data['category'] as String,
      paidByName: data['paidByName'] as String,
      amount: (data['amount'] as num).toDouble(),
      date: timestamp?.toDate() ?? DateTime.now(),
    );
  }
}

class GroupService {
  GroupService._();
  static final GroupService instance = GroupService._();

  static const _inviteAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  final _firestore = FirebaseFirestore.instance;
  final _random = Random.secure();

  User get _user {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Sign in to use shared groups.');
    return user;
  }

  CollectionReference<Map<String, dynamic>> get _myGroups =>
      _firestore.collection('users').doc(_user.uid).collection('groups');

  Stream<List<GroupSummary>> watchGroups() {
    return _myGroups.snapshots().asyncMap((snapshot) async {
      final groups = await Future.wait(
        snapshot.docs.map((doc) async {
          final group = await _firestore.collection('groups').doc(doc.id).get();
          final creatorId = group.data()?['createdBy'] as String?;
          if (creatorId == null) {
            throw StateError('Group "${doc.data()['name']}" has no creator.');
          }
          return GroupSummary.fromMap(doc.id, doc.data(), creatorId: creatorId);
        }),
      );
      groups.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      return groups;
    });
  }

  Stream<List<GroupMember>> watchMembers(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('members')
        .orderBy('joinedAt')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(GroupMember.fromDocument).toList(),
        );
  }

  Stream<List<GroupExpense>> watchExpenses(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('expenses')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(GroupExpense.fromDocument).toList(),
        );
  }

  Future<void> createGroup({
    required String name,
    required String currencyCode,
    required double contribution,
  }) async {
    final user = _user;
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) throw ArgumentError('Enter a group name.');
    if (!contribution.isFinite || contribution < 0) {
      throw ArgumentError('Contribution must be zero or more.');
    }

    final groupRef = _firestore.collection('groups').doc();
    final memberName = user.displayName?.trim();
    final displayName = memberName == null || memberName.isEmpty
        ? (user.email?.split('@').first ?? 'Member')
        : memberName;
    final groupData = {
      'name': trimmedName,
      'currencyCode': currencyCode,
      'createdBy': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
    };

    for (var attempt = 0; attempt < 5; attempt++) {
      final inviteCode = _newInviteCode();
      final inviteRef = _firestore.collection('groupInvites').doc(inviteCode);
      final created = await _firestore.runTransaction<bool>((
        transaction,
      ) async {
        final existingInvite = await transaction.get(inviteRef);
        if (existingInvite.exists) return false;

        transaction.set(groupRef, groupData);
        transaction.set(inviteRef, {
          'groupId': groupRef.id,
          'groupName': trimmedName,
          'currencyCode': currencyCode,
          'createdBy': user.uid,
        });
        transaction.set(groupRef.collection('members').doc(user.uid), {
          'name': displayName,
          'contribution': contribution,
          'joinedAt': FieldValue.serverTimestamp(),
        });
        transaction.set(_myGroups.doc(groupRef.id), {
          'name': trimmedName,
          'currencyCode': currencyCode,
          'inviteCode': inviteCode,
          'createdAt': FieldValue.serverTimestamp(),
        });
        return true;
      });
      if (created) return;
      if (attempt == 4) {
        throw StateError('Could not create a unique invite code. Try again.');
      }
    }
  }

  Future<void> joinGroup({
    required String inviteCode,
    required double contribution,
  }) async {
    final user = _user;
    final code = inviteCode.trim().toUpperCase();
    if (!RegExp(r'^[A-HJ-NP-Z2-9]{8}$').hasMatch(code)) {
      throw ArgumentError('Enter the 8-character group invite code.');
    }
    if (!contribution.isFinite || contribution < 0) {
      throw ArgumentError('Contribution must be zero or more.');
    }

    final inviteRef = _firestore.collection('groupInvites').doc(code);
    final invite = await inviteRef.get();
    if (!invite.exists) throw StateError('That invite code is not valid.');
    final groupId = invite.data()?['groupId'] as String?;
    if (groupId == null || groupId.isEmpty) {
      throw StateError('That invite code is no longer valid.');
    }

    final groupRef = _firestore.collection('groups').doc(groupId);
    final memberRef = groupRef.collection('members').doc(user.uid);
    final myGroupRef = _myGroups.doc(groupId);
    final memberName = user.displayName?.trim();
    final displayName = memberName == null || memberName.isEmpty
        ? (user.email?.split('@').first ?? 'Member')
        : memberName;

    final joined = await _firestore.runTransaction<bool>((transaction) async {
      final currentInvite = await transaction.get(inviteRef);
      final currentGroup = await transaction.get(groupRef);
      final existingMembership = await transaction.get(myGroupRef);
      if (existingMembership.exists) return false;
      if (!currentInvite.exists ||
          currentInvite.data()?['groupId'] != groupId ||
          !currentGroup.exists ||
          currentGroup.data()?['deleting'] == true) {
        throw StateError('That invite code is no longer valid.');
      }

      transaction.set(memberRef, {
        'name': displayName,
        'contribution': contribution,
        'joinedAt': FieldValue.serverTimestamp(),
      });
      transaction.set(myGroupRef, {
        'name': invite.data()?['groupName'] as String? ?? 'Shared group',
        'currencyCode': invite.data()?['currencyCode'] as String? ?? 'PKR',
        'inviteCode': code,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    });
    if (!joined) throw StateError('You are already a member of this group.');
  }

  Future<void> addContribution({
    required String groupId,
    required double amount,
  }) async {
    if (!amount.isFinite || amount <= 0) {
      throw ArgumentError('Enter an amount greater than zero.');
    }
    final groupRef = _firestore.collection('groups').doc(groupId);
    final memberRef = groupRef.collection('members').doc(_user.uid);
    await _firestore.runTransaction((transaction) async {
      final group = await transaction.get(groupRef);
      final member = await transaction.get(memberRef);
      if (!group.exists || group.data()?['deleting'] == true) {
        throw StateError('This group is being deleted.');
      }
      if (!member.exists) {
        throw StateError('You are no longer a member of this group.');
      }
      transaction.update(memberRef, {
        'contribution': FieldValue.increment(amount),
      });
    });
  }

  Future<void> addExpense({
    required String groupId,
    required String title,
    required String category,
    required double amount,
  }) async {
    final user = _user;
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) throw ArgumentError('Enter an expense name.');
    if (!amount.isFinite || amount <= 0) {
      throw ArgumentError('Enter an amount greater than zero.');
    }

    final displayName = user.displayName?.trim();
    final groupRef = _firestore.collection('groups').doc(groupId);
    final memberRef = groupRef.collection('members').doc(user.uid);
    final expenseRef = groupRef.collection('expenses').doc();
    await _firestore.runTransaction((transaction) async {
      final group = await transaction.get(groupRef);
      final member = await transaction.get(memberRef);
      if (!group.exists || group.data()?['deleting'] == true) {
        throw StateError('This group is being deleted.');
      }
      if (!member.exists) {
        throw StateError('You are no longer a member of this group.');
      }
      transaction.set(expenseRef, {
        'title': trimmedTitle,
        'category': category,
        'amount': amount,
        'paidBy': user.uid,
        'paidByName': displayName == null || displayName.isEmpty
            ? (user.email?.split('@').first ?? 'Member')
            : displayName,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> deleteGroup(String groupId) async {
    final user = _user;
    final groupRef = _firestore.collection('groups').doc(groupId);
    final group = await groupRef.get();
    if (group.data()?['createdBy'] != user.uid) {
      throw StateError('Only the group creator can delete this group.');
    }
    if (group.data()?['deleting'] != true) {
      await groupRef.update({'deleting': true});
    }

    final membership = await _myGroups.doc(groupId).get();
    final inviteCode = membership.data()?['inviteCode'] as String?;
    final members = await groupRef.collection('members').get();
    final expenses = await groupRef.collection('expenses').get();
    DocumentReference<Map<String, dynamic>>? inviteRef;
    if (inviteCode != null && inviteCode.isNotEmpty) {
      final candidate = _firestore.collection('groupInvites').doc(inviteCode);
      final invite = await candidate.get();
      if (invite.data()?['groupId'] == groupId) inviteRef = candidate;
    }

    final deletions = <DocumentReference<Map<String, dynamic>>>[];
    for (final member in members.docs) {
      if (member.id == user.uid) continue;
      deletions
        ..add(member.reference)
        ..add(
          _firestore
              .collection('users')
              .doc(member.id)
              .collection('groups')
              .doc(groupId),
        );
    }
    for (final expense in expenses.docs) {
      deletions.add(expense.reference);
    }

    for (var offset = 0; offset < deletions.length; offset += 500) {
      final batch = _firestore.batch();
      for (final reference in deletions.skip(offset).take(500)) {
        batch.delete(reference);
      }
      await batch.commit();
    }

    final finalBatch = _firestore.batch();
    finalBatch
      ..delete(groupRef.collection('members').doc(user.uid))
      ..delete(_myGroups.doc(groupId));
    if (inviteRef != null) finalBatch.delete(inviteRef);
    finalBatch.delete(groupRef);
    await finalBatch.commit();
  }

  String _newInviteCode() => List.generate(
    8,
    (_) => _inviteAlphabet[_random.nextInt(_inviteAlphabet.length)],
  ).join();
}
