import sys
import random


file = open('1325.txt', 'a')

def acc():
	for i in range(100000000000, 100000000200, 1):
		file.write('INSERT INTO account (account_id) VALUES ('+ str(i + 1) +');\n')

def per():		
	for i in range(12):
		file.write('INSERT INTO period (period_id, fin_period) VALUES ('+ str(i+1) +', TO_DATE(\'2019-' + '%02d' % (i+1) + '-01\', \'YYYY-MM-DD\'));\n')

def bil():		
	k = 0	
	
	for i in range(100000000000, 100000000200, 1):
		for j in range(12):
			file.write('INSERT INTO bill (bill_id, account_id, period_id) VALUES ('+ str(k+10000000) +','+ str(i + 1) +', '+ str(j + 1) +');\n')
			k += 1

def bill_det():
	for i in range(15000):
		bill_id = random.randrange(10000000, 10002399, 1)
		service_id = random.randint(1, 5)
		val = random.uniform(1, 10000)
		file.write('INSERT INTO bill_det (bill_det_id, bill_id, service_id, val_$) VALUES ('
			+ str(i+1) + ', ' + str(bill_id) + ', ' + str(service_id) + ', ' + str(round(val, 2)) +');\n')

def adj():
	for i in range(5000):
		bill_id = random.randrange(10000000, 10002399, 1)
		account_id = random.randrange(100000000000, 100000000200, 1)
		service_id = random.randint(1, 5)
		val = random.uniform(-10000, 10000)
		file.write('INSERT INTO adj (account_id, bill_id, service_id, val_$) VALUES ((SELECT account_id FROM bill WHERE bill_id = '+ str(bill_id) + '), ' + str(bill_id) + ', ' + str(service_id) + ', ' + str(round(val, 2)) +');\n')
			
			
def payment():
	for i in range(5000):
		bill_id = random.randrange(10000001, 10002400, 1)
		val = random.uniform(-20000, 0)
		file.write('INSERT INTO payment (payment_id, bill_id, val_$) VALUES ('
			+ str(i+1) + ', ' + str(bill_id) + ', ' + str(round(val, 2)) +');\n')
			
##acc()
##per()
##bil()
##bill_det()
##adj()
payment()