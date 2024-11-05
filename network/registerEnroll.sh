#!/bin/bash

function createuniversity() {
  echo "Enrolling the CA admin"
  mkdir -p organizations/peerOrganizations/university.scholar.com/

  export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/peerOrganizations/university.scholar.com/

  set -x
  fabric-ca-client enroll -u https://admin:adminpw@localhost:7056 --caname ca-university --tls.certfiles "${PWD}/organizations/fabric-ca/university/ca-cert.pem"
  { set +x; } 2>/dev/null

  echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-7056-ca-university.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-7056-ca-university.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-7056-ca-university.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-7056-ca-university.pem
    OrganizationalUnitIdentifier: orderer' > "${PWD}/organizations/peerOrganizations/university.scholar.com/msp/config.yaml"

  # Since the CA serves as both the organization CA and TLS CA, copy the org's root cert that was generated by CA startup into the org level ca and tlsca directories

  # Copy university's CA cert to university's /msp/tlscacerts directory (for use in the channel MSP definition)
  mkdir -p "${PWD}/organizations/peerOrganizations/university.scholar.com/msp/tlscacerts"
  cp "${PWD}/organizations/fabric-ca/university/ca-cert.pem" "${PWD}/organizations/peerOrganizations/university.scholar.com/msp/tlscacerts/ca.crt"

  # Copy university's CA cert to university's /tlsca directory (for use by clients)
  mkdir -p "${PWD}/organizations/peerOrganizations/university.scholar.com/tlsca"
  cp "${PWD}/organizations/fabric-ca/university/ca-cert.pem" "${PWD}/organizations/peerOrganizations/university.scholar.com/tlsca/tlsca.university.scholar.com-cert.pem"

  # Copy university's CA cert to university's /ca directory (for use by clients)
  mkdir -p "${PWD}/organizations/peerOrganizations/university.scholar.com/ca"
  cp "${PWD}/organizations/fabric-ca/university/ca-cert.pem" "${PWD}/organizations/peerOrganizations/university.scholar.com/ca/ca.university.scholar.com-cert.pem"

  echo "Registering peer0"
  set -x
  fabric-ca-client register --caname ca-university --id.name peer0 --id.secret peer0pw --id.type peer --tls.certfiles "${PWD}/organizations/fabric-ca/university/ca-cert.pem"
  { set +x; } 2>/dev/null

  echo "Registering peer1"
  set -x
  fabric-ca-client register --caname ca-university --id.name peer1 --id.secret peer1pw --id.type peer --tls.certfiles "${PWD}/organizations/fabric-ca/university/ca-cert.pem"
  { set +x; } 2>/dev/null

  echo "Registering user"
  set -x
  fabric-ca-client register --caname ca-university --id.name user1 --id.secret user1pw --id.type client --tls.certfiles "${PWD}/organizations/fabric-ca/university/ca-cert.pem"
  { set +x; } 2>/dev/null

  echo "Registering the org admin"
  set -x
  fabric-ca-client register --caname ca-university --id.name universityadmin --id.secret universityadminpw --id.type admin --tls.certfiles "${PWD}/organizations/fabric-ca/university/ca-cert.pem"
  { set +x; } 2>/dev/null

  echo "Generating the peer0 msp"
  set -x
  fabric-ca-client enroll -u https://peer0:peer0pw@localhost:7056 --caname ca-university -M "${PWD}/organizations/peerOrganizations/university.scholar.com/peers/peer0.university.scholar.com/msp" --tls.certfiles "${PWD}/organizations/fabric-ca/university/ca-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/peerOrganizations/university.scholar.com/msp/config.yaml" "${PWD}/organizations/peerOrganizations/university.scholar.com/peers/peer0.university.scholar.com/msp/config.yaml"

  echo "Generating the peer0-tls certificates, use --csr.hosts to specify Subject Alternative Names"
  set -x
  fabric-ca-client enroll -u https://peer0:peer0pw@localhost:7056 --caname ca-university -M "${PWD}/organizations/peerOrganizations/university.scholar.com/peers/peer0.university.scholar.com/tls" --enrollment.profile tls --csr.hosts peer0.university.scholar.com --csr.hosts localhost --tls.certfiles "${PWD}/organizations/fabric-ca/university/ca-cert.pem"
  { set +x; } 2>/dev/null

  # Copy the tls CA cert, server cert, server keystore to well known file names in the peer's tls directory that are referenced by peer startup config
  cp "${PWD}/organizations/peerOrganizations/university.scholar.com/peers/peer0.university.scholar.com/tls/tlscacerts/"* "${PWD}/organizations/peerOrganizations/university.scholar.com/peers/peer0.university.scholar.com/tls/ca.crt"
  cp "${PWD}/organizations/peerOrganizations/university.scholar.com/peers/peer0.university.scholar.com/tls/signcerts/"* "${PWD}/organizations/peerOrganizations/university.scholar.com/peers/peer0.university.scholar.com/tls/server.crt"
  cp "${PWD}/organizations/peerOrganizations/university.scholar.com/peers/peer0.university.scholar.com/tls/keystore/"* "${PWD}/organizations/peerOrganizations/university.scholar.com/peers/peer0.university.scholar.com/tls/server.key"

  ##new
  echo "Generating the peer1 msp"
  set -x
  fabric-ca-client enroll -u https://peer1:peer1pw@localhost:7056 --caname ca-university -M "${PWD}/organizations/peerOrganizations/university.scholar.com/peers/peer1.university.scholar.com/msp" --tls.certfiles "${PWD}/organizations/fabric-ca/university/ca-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/peerOrganizations/university.scholar.com/msp/config.yaml" "${PWD}/organizations/peerOrganizations/university.scholar.com/peers/peer1.university.scholar.com/msp/config.yaml"

  echo "Generating the peer1-tls certificates, use --csr.hosts to specify Subject Alternative Names"
  set -x
  fabric-ca-client enroll -u https://peer1:peer1pw@localhost:7056 --caname ca-university -M "${PWD}/organizations/peerOrganizations/university.scholar.com/peers/peer1.university.scholar.com/tls" --enrollment.profile tls --csr.hosts peer1.university.scholar.com --csr.hosts localhost --tls.certfiles "${PWD}/organizations/fabric-ca/university/ca-cert.pem"
  { set +x; } 2>/dev/null

  # Copy the tls CA cert, server cert, server keystore to well known file names in the peer's tls directory that are referenced by peer startup config
  cp "${PWD}/organizations/peerOrganizations/university.scholar.com/peers/peer1.university.scholar.com/tls/tlscacerts/"* "${PWD}/organizations/peerOrganizations/university.scholar.com/peers/peer1.university.scholar.com/tls/ca.crt"
  cp "${PWD}/organizations/peerOrganizations/university.scholar.com/peers/peer1.university.scholar.com/tls/signcerts/"* "${PWD}/organizations/peerOrganizations/university.scholar.com/peers/peer1.university.scholar.com/tls/server.crt"
  cp "${PWD}/organizations/peerOrganizations/university.scholar.com/peers/peer1.university.scholar.com/tls/keystore/"* "${PWD}/organizations/peerOrganizations/university.scholar.com/peers/peer1.university.scholar.com/tls/server.key"

  echo "Generating the user msp"
  set -x
  fabric-ca-client enroll -u https://user1:user1pw@localhost:7056 --caname ca-university -M "${PWD}/organizations/peerOrganizations/university.scholar.com/users/User1@university.scholar.com/msp" --tls.certfiles "${PWD}/organizations/fabric-ca/university/ca-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/peerOrganizations/university.scholar.com/msp/config.yaml" "${PWD}/organizations/peerOrganizations/university.scholar.com/users/User1@university.scholar.com/msp/config.yaml"

  echo "Generating the org admin msp"
  set -x
  fabric-ca-client enroll -u https://universityadmin:universityadminpw@localhost:7056 --caname ca-university -M "${PWD}/organizations/peerOrganizations/university.scholar.com/users/Admin@university.scholar.com/msp" --tls.certfiles "${PWD}/organizations/fabric-ca/university/ca-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/peerOrganizations/university.scholar.com/msp/config.yaml" "${PWD}/organizations/peerOrganizations/university.scholar.com/users/Admin@university.scholar.com/msp/config.yaml"
}

function createscholarshipDepartment() {
  echo "Enrolling the CA admin"
  mkdir -p organizations/peerOrganizations/scholarshipDepartment.scholar.com/

  export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/peerOrganizations/scholarshipDepartment.scholar.com/

  set -x
  fabric-ca-client enroll -u https://admin:adminpw@localhost:7054 --caname ca-scholarshipDepartment --tls.certfiles "${PWD}/organizations/fabric-ca/scholarshipDepartment/ca-cert.pem"
  { set +x; } 2>/dev/null

  echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-scholarshipDepartment.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-scholarshipDepartment.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-scholarshipDepartment.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-scholarshipDepartment.pem
    OrganizationalUnitIdentifier: orderer' > "${PWD}/organizations/peerOrganizations/scholarshipDepartment.scholar.com/msp/config.yaml"

  # Since the CA serves as both the organization CA and TLS CA, copy the org's root cert that was generated by CA startup into the org level ca and tlsca directories

  # Copy scholarshipDepartment's CA cert to scholarshipDepartment's /msp/tlscacerts directory (for use in the channel MSP definition)
  mkdir -p "${PWD}/organizations/peerOrganizations/scholarshipDepartment.scholar.com/msp/tlscacerts"
  cp "${PWD}/organizations/fabric-ca/scholarshipDepartment/ca-cert.pem" "${PWD}/organizations/peerOrganizations/scholarshipDepartment.scholar.com/msp/tlscacerts/ca.crt"

  # Copy scholarshipDepartment's CA cert to scholarshipDepartment's /tlsca directory (for use by clients)
  mkdir -p "${PWD}/organizations/peerOrganizations/scholarshipDepartment.scholar.com/tlsca"
  cp "${PWD}/organizations/fabric-ca/scholarshipDepartment/ca-cert.pem" "${PWD}/organizations/peerOrganizations/scholarshipDepartment.scholar.com/tlsca/tlsca.scholarshipDepartment.scholar.com-cert.pem"

  # Copy scholarshipDepartment's CA cert to scholarshipDepartment's /ca directory (for use by clients)
  mkdir -p "${PWD}/organizations/peerOrganizations/scholarshipDepartment.scholar.com/ca"
  cp "${PWD}/organizations/fabric-ca/scholarshipDepartment/ca-cert.pem" "${PWD}/organizations/peerOrganizations/scholarshipDepartment.scholar.com/ca/ca.scholarshipDepartment.scholar.com-cert.pem"

  echo "Registering peer0"
  set -x
  fabric-ca-client register --caname ca-scholarshipDepartment --id.name peer0 --id.secret peer0pw --id.type peer --tls.certfiles "${PWD}/organizations/fabric-ca/scholarshipDepartment/ca-cert.pem"
  { set +x; } 2>/dev/null

  echo "Registering user"
  set -x
  fabric-ca-client register --caname ca-scholarshipDepartment --id.name user1 --id.secret user1pw --id.type client --tls.certfiles "${PWD}/organizations/fabric-ca/scholarshipDepartment/ca-cert.pem"
  { set +x; } 2>/dev/null

  echo "Registering the org admin"
  set -x
  fabric-ca-client register --caname ca-scholarshipDepartment --id.name scholarshipDepartmentadmin --id.secret scholarshipDepartmentadminpw --id.type admin --tls.certfiles "${PWD}/organizations/fabric-ca/scholarshipDepartment/ca-cert.pem"
  { set +x; } 2>/dev/null

  echo "Generating the peer0 msp"
  set -x
  fabric-ca-client enroll -u https://peer0:peer0pw@localhost:7054 --caname ca-scholarshipDepartment -M "${PWD}/organizations/peerOrganizations/scholarshipDepartment.scholar.com/peers/peer0.scholarshipDepartment.scholar.com/msp" --tls.certfiles "${PWD}/organizations/fabric-ca/scholarshipDepartment/ca-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/peerOrganizations/scholarshipDepartment.scholar.com/msp/config.yaml" "${PWD}/organizations/peerOrganizations/scholarshipDepartment.scholar.com/peers/peer0.scholarshipDepartment.scholar.com/msp/config.yaml"

  echo "Generating the peer0-tls certificates, use --csr.hosts to specify Subject Alternative Names"
  set -x
  fabric-ca-client enroll -u https://peer0:peer0pw@localhost:7054 --caname ca-scholarshipDepartment -M "${PWD}/organizations/peerOrganizations/scholarshipDepartment.scholar.com/peers/peer0.scholarshipDepartment.scholar.com/tls" --enrollment.profile tls --csr.hosts peer0.scholarshipDepartment.scholar.com --csr.hosts localhost --tls.certfiles "${PWD}/organizations/fabric-ca/scholarshipDepartment/ca-cert.pem"
  { set +x; } 2>/dev/null

  # Copy the tls CA cert, server cert, server keystore to well known file names in the peer's tls directory that are referenced by peer startup config
  cp "${PWD}/organizations/peerOrganizations/scholarshipDepartment.scholar.com/peers/peer0.scholarshipDepartment.scholar.com/tls/tlscacerts/"* "${PWD}/organizations/peerOrganizations/scholarshipDepartment.scholar.com/peers/peer0.scholarshipDepartment.scholar.com/tls/ca.crt"
  cp "${PWD}/organizations/peerOrganizations/scholarshipDepartment.scholar.com/peers/peer0.scholarshipDepartment.scholar.com/tls/signcerts/"* "${PWD}/organizations/peerOrganizations/scholarshipDepartment.scholar.com/peers/peer0.scholarshipDepartment.scholar.com/tls/server.crt"
  cp "${PWD}/organizations/peerOrganizations/scholarshipDepartment.scholar.com/peers/peer0.scholarshipDepartment.scholar.com/tls/keystore/"* "${PWD}/organizations/peerOrganizations/scholarshipDepartment.scholar.com/peers/peer0.scholarshipDepartment.scholar.com/tls/server.key"

  echo "Generating the user msp"
  set -x
  fabric-ca-client enroll -u https://user1:user1pw@localhost:7054 --caname ca-scholarshipDepartment -M "${PWD}/organizations/peerOrganizations/scholarshipDepartment.scholar.com/users/User1@scholarshipDepartment.scholar.com/msp" --tls.certfiles "${PWD}/organizations/fabric-ca/scholarshipDepartment/ca-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/peerOrganizations/scholarshipDepartment.scholar.com/msp/config.yaml" "${PWD}/organizations/peerOrganizations/scholarshipDepartment.scholar.com/users/User1@scholarshipDepartment.scholar.com/msp/config.yaml"

  echo "Generating the org admin msp"
  set -x
  fabric-ca-client enroll -u https://scholarshipDepartmentadmin:scholarshipDepartmentadminpw@localhost:7054 --caname ca-scholarshipDepartment -M "${PWD}/organizations/peerOrganizations/scholarshipDepartment.scholar.com/users/Admin@scholarshipDepartment.scholar.com/msp" --tls.certfiles "${PWD}/organizations/fabric-ca/scholarshipDepartment/ca-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/peerOrganizations/scholarshipDepartment.scholar.com/msp/config.yaml" "${PWD}/organizations/peerOrganizations/scholarshipDepartment.scholar.com/users/Admin@scholarshipDepartment.scholar.com/msp/config.yaml"
}

function createtreasury() {
  echo "Enrolling the CA admin"
  mkdir -p organizations/peerOrganizations/treasury.scholar.com/

  export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/peerOrganizations/treasury.scholar.com/

  set -x
  fabric-ca-client enroll -u https://admin:adminpw@localhost:8054 --caname ca-treasury --tls.certfiles "${PWD}/organizations/fabric-ca/treasury/ca-cert.pem"
  { set +x; } 2>/dev/null

  echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-8054-ca-treasury.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-8054-ca-treasury.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-8054-ca-treasury.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-8054-ca-treasury.pem
    OrganizationalUnitIdentifier: orderer' > "${PWD}/organizations/peerOrganizations/treasury.scholar.com/msp/config.yaml"

  # Since the CA serves as both the organization CA and TLS CA, copy the org's root cert that was generated by CA startup into the org level ca and tlsca directories

  # Copy treasury's CA cert to treasury's /msp/tlscacerts directory (for use in the channel MSP definition)
  mkdir -p "${PWD}/organizations/peerOrganizations/treasury.scholar.com/msp/tlscacerts"
  cp "${PWD}/organizations/fabric-ca/treasury/ca-cert.pem" "${PWD}/organizations/peerOrganizations/treasury.scholar.com/msp/tlscacerts/ca.crt"

  # Copy treasury's CA cert to treasury's /tlsca directory (for use by clients)
  mkdir -p "${PWD}/organizations/peerOrganizations/treasury.scholar.com/tlsca"
  cp "${PWD}/organizations/fabric-ca/treasury/ca-cert.pem" "${PWD}/organizations/peerOrganizations/treasury.scholar.com/tlsca/tlsca.treasury.scholar.com-cert.pem"

  # Copy treasury's CA cert to treasury's /ca directory (for use by clients)
  mkdir -p "${PWD}/organizations/peerOrganizations/treasury.scholar.com/ca"
  cp "${PWD}/organizations/fabric-ca/treasury/ca-cert.pem" "${PWD}/organizations/peerOrganizations/treasury.scholar.com/ca/ca.treasury.scholar.com-cert.pem"

  echo "Registering peer0"
  set -x
  fabric-ca-client register --caname ca-treasury --id.name peer0 --id.secret peer0pw --id.type peer --tls.certfiles "${PWD}/organizations/fabric-ca/treasury/ca-cert.pem"
  { set +x; } 2>/dev/null

  echo "Registering user"
  set -x
  fabric-ca-client register --caname ca-treasury --id.name user1 --id.secret user1pw --id.type client --tls.certfiles "${PWD}/organizations/fabric-ca/treasury/ca-cert.pem"
  { set +x; } 2>/dev/null

  echo "Registering the org admin"
  set -x
  fabric-ca-client register --caname ca-treasury --id.name treasuryadmin --id.secret treasuryadminpw --id.type admin --tls.certfiles "${PWD}/organizations/fabric-ca/treasury/ca-cert.pem"
  { set +x; } 2>/dev/null

  echo "Generating the peer0 msp"
  set -x
  fabric-ca-client enroll -u https://peer0:peer0pw@localhost:8054 --caname ca-treasury -M "${PWD}/organizations/peerOrganizations/treasury.scholar.com/peers/peer0.treasury.scholar.com/msp" --tls.certfiles "${PWD}/organizations/fabric-ca/treasury/ca-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/peerOrganizations/treasury.scholar.com/msp/config.yaml" "${PWD}/organizations/peerOrganizations/treasury.scholar.com/peers/peer0.treasury.scholar.com/msp/config.yaml"

  echo "Generating the peer0-tls certificates, use --csr.hosts to specify Subject Alternative Names"
  set -x
  fabric-ca-client enroll -u https://peer0:peer0pw@localhost:8054 --caname ca-treasury -M "${PWD}/organizations/peerOrganizations/treasury.scholar.com/peers/peer0.treasury.scholar.com/tls" --enrollment.profile tls --csr.hosts peer0.treasury.scholar.com --csr.hosts localhost --tls.certfiles "${PWD}/organizations/fabric-ca/treasury/ca-cert.pem"
  { set +x; } 2>/dev/null

  # Copy the tls CA cert, server cert, server keystore to well known file names in the peer's tls directory that are referenced by peer startup config
  cp "${PWD}/organizations/peerOrganizations/treasury.scholar.com/peers/peer0.treasury.scholar.com/tls/tlscacerts/"* "${PWD}/organizations/peerOrganizations/treasury.scholar.com/peers/peer0.treasury.scholar.com/tls/ca.crt"
  cp "${PWD}/organizations/peerOrganizations/treasury.scholar.com/peers/peer0.treasury.scholar.com/tls/signcerts/"* "${PWD}/organizations/peerOrganizations/treasury.scholar.com/peers/peer0.treasury.scholar.com/tls/server.crt"
  cp "${PWD}/organizations/peerOrganizations/treasury.scholar.com/peers/peer0.treasury.scholar.com/tls/keystore/"* "${PWD}/organizations/peerOrganizations/treasury.scholar.com/peers/peer0.treasury.scholar.com/tls/server.key"

  echo "Generating the user msp"
  set -x
  fabric-ca-client enroll -u https://user1:user1pw@localhost:8054 --caname ca-treasury -M "${PWD}/organizations/peerOrganizations/treasury.scholar.com/users/User1@treasury.scholar.com/msp" --tls.certfiles "${PWD}/organizations/fabric-ca/treasury/ca-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/peerOrganizations/treasury.scholar.com/msp/config.yaml" "${PWD}/organizations/peerOrganizations/treasury.scholar.com/users/User1@treasury.scholar.com/msp/config.yaml"

  echo "Generating the org admin msp"
  set -x
  fabric-ca-client enroll -u https://treasuryadmin:treasuryadminpw@localhost:8054 --caname ca-treasury -M "${PWD}/organizations/peerOrganizations/treasury.scholar.com/users/Admin@treasury.scholar.com/msp" --tls.certfiles "${PWD}/organizations/fabric-ca/treasury/ca-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/peerOrganizations/treasury.scholar.com/msp/config.yaml" "${PWD}/organizations/peerOrganizations/treasury.scholar.com/users/Admin@treasury.scholar.com/msp/config.yaml"
}

#new start
function createauditor() {
  echo "Enrolling the CA admin"
  mkdir -p organizations/peerOrganizations/auditor.scholar.com/

  export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/peerOrganizations/auditor.scholar.com/

  set -x
  fabric-ca-client enroll -u https://admin:adminpw@localhost:8055 --caname ca-auditor --tls.certfiles "${PWD}/organizations/fabric-ca/auditor/ca-cert.pem"
  { set +x; } 2>/dev/null

  echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-8055-ca-auditor.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-8055-ca-auditor.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-8055-ca-auditor.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-8055-ca-auditor.pem
    OrganizationalUnitIdentifier: orderer' > "${PWD}/organizations/peerOrganizations/auditor.scholar.com/msp/config.yaml"

  # Since the CA serves as both the organization CA and TLS CA, copy the org's root cert that was generated by CA startup into the org level ca and tlsca directories

  # Copy auditor's CA cert to auditor's /msp/tlscacerts directory (for use in the channel MSP definition)
  mkdir -p "${PWD}/organizations/peerOrganizations/auditor.scholar.com/msp/tlscacerts"
  cp "${PWD}/organizations/fabric-ca/auditor/ca-cert.pem" "${PWD}/organizations/peerOrganizations/auditor.scholar.com/msp/tlscacerts/ca.crt"

  # Copy auditor's CA cert to auditor's /tlsca directory (for use by clients)
  mkdir -p "${PWD}/organizations/peerOrganizations/auditor.scholar.com/tlsca"
  cp "${PWD}/organizations/fabric-ca/auditor/ca-cert.pem" "${PWD}/organizations/peerOrganizations/auditor.scholar.com/tlsca/tlsca.auditor.scholar.com-cert.pem"

  # Copy auditor's CA cert to auditor's /ca directory (for use by clients)
  mkdir -p "${PWD}/organizations/peerOrganizations/auditor.scholar.com/ca"
  cp "${PWD}/organizations/fabric-ca/auditor/ca-cert.pem" "${PWD}/organizations/peerOrganizations/auditor.scholar.com/ca/ca.auditor.scholar.com-cert.pem"

  echo "Registering peer0"
  set -x
  fabric-ca-client register --caname ca-auditor --id.name peer0 --id.secret peer0pw --id.type peer --tls.certfiles "${PWD}/organizations/fabric-ca/auditor/ca-cert.pem"
  { set +x; } 2>/dev/null

  echo "Registering user"
  set -x
  fabric-ca-client register --caname ca-auditor --id.name user1 --id.secret user1pw --id.type client --tls.certfiles "${PWD}/organizations/fabric-ca/auditor/ca-cert.pem"
  { set +x; } 2>/dev/null

  echo "Registering the org admin"
  set -x
  fabric-ca-client register --caname ca-auditor --id.name auditoradmin --id.secret auditoradminpw --id.type admin --tls.certfiles "${PWD}/organizations/fabric-ca/auditor/ca-cert.pem"
  { set +x; } 2>/dev/null

  echo "Generating the peer0 msp"
  set -x
  fabric-ca-client enroll -u https://peer0:peer0pw@localhost:8055 --caname ca-auditor -M "${PWD}/organizations/peerOrganizations/auditor.scholar.com/peers/peer0.auditor.scholar.com/msp" --tls.certfiles "${PWD}/organizations/fabric-ca/auditor/ca-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/peerOrganizations/auditor.scholar.com/msp/config.yaml" "${PWD}/organizations/peerOrganizations/auditor.scholar.com/peers/peer0.auditor.scholar.com/msp/config.yaml"

  echo "Generating the peer0-tls certificates, use --csr.hosts to specify Subject Alternative Names"
  set -x
  fabric-ca-client enroll -u https://peer0:peer0pw@localhost:8055 --caname ca-auditor -M "${PWD}/organizations/peerOrganizations/auditor.scholar.com/peers/peer0.auditor.scholar.com/tls" --enrollment.profile tls --csr.hosts peer0.auditor.scholar.com --csr.hosts localhost --tls.certfiles "${PWD}/organizations/fabric-ca/auditor/ca-cert.pem"
  { set +x; } 2>/dev/null

  # Copy the tls CA cert, server cert, server keystore to well known file names in the peer's tls directory that are referenced by peer startup config
  cp "${PWD}/organizations/peerOrganizations/auditor.scholar.com/peers/peer0.auditor.scholar.com/tls/tlscacerts/"* "${PWD}/organizations/peerOrganizations/auditor.scholar.com/peers/peer0.auditor.scholar.com/tls/ca.crt"
  cp "${PWD}/organizations/peerOrganizations/auditor.scholar.com/peers/peer0.auditor.scholar.com/tls/signcerts/"* "${PWD}/organizations/peerOrganizations/auditor.scholar.com/peers/peer0.auditor.scholar.com/tls/server.crt"
  cp "${PWD}/organizations/peerOrganizations/auditor.scholar.com/peers/peer0.auditor.scholar.com/tls/keystore/"* "${PWD}/organizations/peerOrganizations/auditor.scholar.com/peers/peer0.auditor.scholar.com/tls/server.key"

  echo "Generating the user msp"
  set -x
  fabric-ca-client enroll -u https://user1:user1pw@localhost:8055 --caname ca-auditor -M "${PWD}/organizations/peerOrganizations/auditor.scholar.com/users/User1@auditor.scholar.com/msp" --tls.certfiles "${PWD}/organizations/fabric-ca/auditor/ca-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/peerOrganizations/auditor.scholar.com/msp/config.yaml" "${PWD}/organizations/peerOrganizations/auditor.scholar.com/users/User1@auditor.scholar.com/msp/config.yaml"

  echo "Generating the org admin msp"
  set -x
  fabric-ca-client enroll -u https://auditoradmin:auditoradminpw@localhost:8055 --caname ca-auditor -M "${PWD}/organizations/peerOrganizations/auditor.scholar.com/users/Admin@auditor.scholar.com/msp" --tls.certfiles "${PWD}/organizations/fabric-ca/auditor/ca-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/peerOrganizations/auditor.scholar.com/msp/config.yaml" "${PWD}/organizations/peerOrganizations/auditor.scholar.com/users/Admin@auditor.scholar.com/msp/config.yaml"
}
#new end

function createOrderer() {
  echo "Enrolling the CA admin"
  mkdir -p organizations/ordererOrganizations/scholar.com

  export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/ordererOrganizations/scholar.com

  set -x
  fabric-ca-client enroll -u https://admin:adminpw@localhost:9054 --caname ca-orderer --tls.certfiles "${PWD}/organizations/fabric-ca/ordererOrg/ca-cert.pem"
  { set +x; } 2>/dev/null

  echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-orderer.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-orderer.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-orderer.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-orderer.pem
    OrganizationalUnitIdentifier: orderer' > "${PWD}/organizations/ordererOrganizations/scholar.com/msp/config.yaml"

  # Since the CA serves as both the organization CA and TLS CA, copy the org's root cert that was generated by CA startup into the org level ca and tlsca directories

  # Copy orderer org's CA cert to orderer org's /msp/tlscacerts directory (for use in the channel MSP definition)
  mkdir -p "${PWD}/organizations/ordererOrganizations/scholar.com/msp/tlscacerts"
  cp "${PWD}/organizations/fabric-ca/ordererOrg/ca-cert.pem" "${PWD}/organizations/ordererOrganizations/scholar.com/msp/tlscacerts/tlsca.scholar.com-cert.pem"

  # Copy orderer org's CA cert to orderer org's /tlsca directory (for use by clients)
  mkdir -p "${PWD}/organizations/ordererOrganizations/scholar.com/tlsca"
  cp "${PWD}/organizations/fabric-ca/ordererOrg/ca-cert.pem" "${PWD}/organizations/ordererOrganizations/scholar.com/tlsca/tlsca.scholar.com-cert.pem"

  echo "Registering orderer"
  set -x
  fabric-ca-client register --caname ca-orderer --id.name orderer --id.secret ordererpw --id.type orderer --tls.certfiles "${PWD}/organizations/fabric-ca/ordererOrg/ca-cert.pem"
  { set +x; } 2>/dev/null

  echo "Registering the orderer admin"
  set -x
  fabric-ca-client register --caname ca-orderer --id.name ordererAdmin --id.secret ordererAdminpw --id.type admin --tls.certfiles "${PWD}/organizations/fabric-ca/ordererOrg/ca-cert.pem"
  { set +x; } 2>/dev/null

  echo "Generating the orderer msp"
  set -x
  fabric-ca-client enroll -u https://orderer:ordererpw@localhost:9054 --caname ca-orderer -M "${PWD}/organizations/ordererOrganizations/scholar.com/orderers/orderer.scholar.com/msp" --tls.certfiles "${PWD}/organizations/fabric-ca/ordererOrg/ca-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/ordererOrganizations/scholar.com/msp/config.yaml" "${PWD}/organizations/ordererOrganizations/scholar.com/orderers/orderer.scholar.com/msp/config.yaml"

  echo "Generating the orderer-tls certificates, use --csr.hosts to specify Subject Alternative Names"
  set -x
  fabric-ca-client enroll -u https://orderer:ordererpw@localhost:9054 --caname ca-orderer -M "${PWD}/organizations/ordererOrganizations/scholar.com/orderers/orderer.scholar.com/tls" --enrollment.profile tls --csr.hosts orderer.scholar.com --csr.hosts localhost --tls.certfiles "${PWD}/organizations/fabric-ca/ordererOrg/ca-cert.pem"
  { set +x; } 2>/dev/null

  # Copy the tls CA cert, server cert, server keystore to well known file names in the orderer's tls directory that are referenced by orderer startup config
  cp "${PWD}/organizations/ordererOrganizations/scholar.com/orderers/orderer.scholar.com/tls/tlscacerts/"* "${PWD}/organizations/ordererOrganizations/scholar.com/orderers/orderer.scholar.com/tls/ca.crt"
  cp "${PWD}/organizations/ordererOrganizations/scholar.com/orderers/orderer.scholar.com/tls/signcerts/"* "${PWD}/organizations/ordererOrganizations/scholar.com/orderers/orderer.scholar.com/tls/server.crt"
  cp "${PWD}/organizations/ordererOrganizations/scholar.com/orderers/orderer.scholar.com/tls/keystore/"* "${PWD}/organizations/ordererOrganizations/scholar.com/orderers/orderer.scholar.com/tls/server.key"

  # Copy orderer org's CA cert to orderer's /msp/tlscacerts directory (for use in the orderer MSP definition)
  mkdir -p "${PWD}/organizations/ordererOrganizations/scholar.com/orderers/orderer.scholar.com/msp/tlscacerts"
  cp "${PWD}/organizations/ordererOrganizations/scholar.com/orderers/orderer.scholar.com/tls/tlscacerts/"* "${PWD}/organizations/ordererOrganizations/scholar.com/orderers/orderer.scholar.com/msp/tlscacerts/tlsca.scholar.com-cert.pem"

  echo "Generating the admin msp"
  set -x
  fabric-ca-client enroll -u https://ordererAdmin:ordererAdminpw@localhost:9054 --caname ca-orderer -M "${PWD}/organizations/ordererOrganizations/scholar.com/users/Admin@scholar.com/msp" --tls.certfiles "${PWD}/organizations/fabric-ca/ordererOrg/ca-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/ordererOrganizations/scholar.com/msp/config.yaml" "${PWD}/organizations/ordererOrganizations/scholar.com/users/Admin@scholar.com/msp/config.yaml"
}

createuniversity
createscholarshipDepartment
createtreasury
createauditor
createOrderer