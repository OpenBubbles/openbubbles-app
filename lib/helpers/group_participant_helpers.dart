import 'package:bluebubbles/database/models.dart';

/// Reconciles a locally cached participant list with the server's latest
/// ordered list.
///
/// The old fetch path only handled length changes and could leave a group
/// stale when one participant was replaced by another. It also added only one
/// handle when several participants were added. Preserve existing Handle
/// objects (and their contact metadata) when the identity is unchanged, while
/// applying the server list exactly once and dropping duplicate identities.
List<Handle> reconcileGroupParticipants(
  List<Handle> current,
  List<Handle> incoming,
) {
  final existingByIdentity = <String, Handle>{};
  for (final handle in current) {
    existingByIdentity.putIfAbsent(handle.uniqueAddressAndService, () => handle);
  }

  final seen = <String>{};
  final reconciled = <Handle>[];
  for (final handle in incoming) {
    final identity = handle.uniqueAddressAndService;
    if (!seen.add(identity)) continue;
    reconciled.add(existingByIdentity[identity] ?? handle);
  }
  return reconciled;
}
