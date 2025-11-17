enum CatalogName {
  agentstatuses,
  allowedplatformlanguages,
  callendedreasons,
  employeeassistancetypes,
  employeetypes,
  hiringprocessemailtypes,
  hiringprocessemailvariables,
  interviewstatuses,
  interviewtypes,
  jobapplicationstatuses,
  menuoptions,
  objecttypesforconfigurations,
  userpermissions,
  usertypes,
}

extension CatalogNameExt on CatalogName {
  String get value => toString().split('.').last;
}
