CREATE TABLE account -- ���� 
(
    account_id NUMBER(12) CONSTRAINT account_pk PRIMARY KEY
)

CREATE TABLE service --������
(
    service_id NUMBER(12) CONSTRAINT service_pk PRIMARY KEY,
    serv_name NVARCHAR2(50) NOT NULL
)

CREATE TABLE period 
(
    period_id NUMBER(12) CONSTRAINT period_pk PRIMARY KEY,
    fin_period DATE NOT NULL
)

CREATE TABLE bill -- ��������� �� �����
(
      bill_id NUMBER(8) CONSTRAINT bill_pk PRIMARY KEY,
      account_id NOT NULL CONSTRAINT bill_fk_account REFERENCES account,
      period_id NOT NULL CONSTRAINT bill_fk_period REFERENCES period
)

CREATE TABLE bill_det -- ���������� �� ������
(
      bill_det_id NUMBER(12) CONSTRAINT bill_det2_pk PRIMARY KEY,
      bill_id NUMBER(12) NOT NULL CONSTRAINT bill_det2_fk_bill REFERENCES bill,
      service_id NUMBER(8) NOT NULL,
      val_$ NUMBER(12, 2) NOT NULL
)


CREATE TABLE adj-- ������������� � ������� (������, ����� ���� � + � -)
(
      account_id NOT NULL CONSTRAINT adj_fk_account REFERENCES account,
      bill_id NUMBER(12) NOT NULL CONSTRAINT adj_fk_bill REFERENCES bill,
      service_id NUMBER(8) NOT NULL,
      val_$ NUMBER(12, 2) NOT NULL
)

CREATE TABLE payment -- ������
(
    payment_id NUMBER(12) CONSTRAINT payment_pk PRIMARY KEY,
    bill_id NUMBER(12) NOT NULL CONSTRAINT payment_fk_bill REFERENCES bill,
    val_$ NUMBER(12, 2) NOT NULL
)

--DROP TABLE payment;

CREATE TABLE payment_det -- ����� �������
(
    account_id NUMBER(12) NOT NULL CONSTRAINT subaccount_fk_account REFERENCES account,
    bill_id NUMBER(12) NOT NULL CONSTRAINT subaccount_fk_bill REFERENCES bill,
    service_id NUMBER(8) NOT NULL,
    val_$ NUMBER(20, 10) NOT NULL
)











