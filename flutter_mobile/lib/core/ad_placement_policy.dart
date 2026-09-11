/// Local ad-placeholder placement. Live ad SDKs are out of scope.
abstract final class AdPlacementPolicy {
  static const Set<String> allowedRoutes = {'/languages', '/export'};

  static bool allows(String location) => allowedRoutes.contains(location);
}
