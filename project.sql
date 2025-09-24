/*
The database contains 8 tables:

* Customers - customer data
* Employees - Employee data
* Offices - Sales office information
* OrderDetails - Sales order line for each sales ORDER
* Payments - Customer payment records
* Prodcuts - List of scale model cars
* ProductLine - List of product line categories 

*/

-- Table Descriptions
SELECT 'Customers' AS table_name, 
	   (SELECT COUNT(*) FROM pragma_table_info('customers')) AS number_of_attributes,
	   (SELECT COUNT(*) FROM customers) AS number_of_rows
  
UNION ALL

SELECT 'Products' AS table_name, 
	   (SELECT COUNT(*) FROM pragma_table_info('products')) AS number_of_attributes,
	   (SELECT COUNT(*) FROM products) AS number_of_rows

UNION ALL

SELECT 'ProductsLines' AS table_name, 
	   (SELECT COUNT(*) FROM pragma_table_info('productlines')) AS number_of_attributes,
	   (SELECT COUNT(*) FROM productlines) AS number_of_rows

UNION ALL

SELECT 'Orders' AS table_name, 
	   (SELECT COUNT(*) FROM pragma_table_info('orders')) AS number_of_attributes,
	   (SELECT COUNT(*) FROM orders) AS number_of_rows

UNION ALL

SELECT 'OrderDetails' AS table_name, 
	   (SELECT COUNT(*) FROM pragma_table_info('orderdetails')) AS number_of_attributes,
	   (SELECT COUNT(*) FROM orderdetails) AS number_of_rows
	   
UNION ALL

SELECT 'Payments' AS table_name, 
	   (SELECT COUNT(*) FROM pragma_table_info('payments')) AS number_of_attributes,
	   (SELECT COUNT(*) FROM payments) AS number_of_rows
	   
UNION ALL

SELECT 'Employees' AS table_name, 
	   (SELECT COUNT(*) FROM pragma_table_info('employees')) AS number_of_attributes,
	   (SELECT COUNT(*) FROM employees) AS number_of_rows
	
UNION ALL

SELECT 'Offices' AS table_name, 
	   (SELECT COUNT(*) FROM pragma_table_info('offices')) AS number_of_attributes,
	   (SELECT COUNT(*) FROM offices) AS number_of_rows;

/* Q1) Which Products Should We Order More of or less of? */
WITH 

-- Low Stock
low_stock_table AS (
SELECT p.productCode,
	   ROUND(SUM(od.quantityOrdered)*1.0 / p.quantityInStock, 2) AS low_stock
  FROM products AS p
  JOIN orderdetails AS od
    ON p.productCode = od.productCode
 GROUP BY p.productCode
 ORDER BY low_stock DESC
 LIMIT 10
), 

-- Product Performance 
restock_products AS (
SELECT productCode, SUM(quantityOrdered * priceEach) AS prod_perf
  FROM orderdetails
 WHERE productCode IN (SELECT productCode
						 FROM low_stock_table)
 GROUP BY productCode
 ORDER BY prod_perf DESC
 LIMIT 10
 )
 
SELECT productCode, productName, productLine
  FROM products as p
 WHERE productCode IN (SELECT productCode
						 FROM restock_products);
 
/* Q2) How Should We Match Marketing & Communication Straegies to Customer Behaviour */

DROP VIEW IF EXISTS profit_generated_per_customer; -- Error handling

CREATE VIEW profit_generated_per_customer
			(customerNumber, profit) AS
SELECT o.customerNumber, SUM(od.quantityOrdered * (od.priceEach - p.buyPrice)) AS profit
  FROM products AS p
  JOIN orderdetails AS od
    ON p.productCode = od.productCode
  JOIN orders AS o
    ON od.orderNumber = o.orderNumber 
 GROUP BY o.customerNumber;


-- Top 5 VIP customers 
SELECT c.contactLastName, c.contactFirstName, c.city, c.country,
	   pgc.profit
  FROM customers AS c
  JOIN profit_generated_per_customer AS pgc
    ON c.customerNumber = pgc.customerNumber
 ORDER BY pgc.profit DESC
 LIMIT 5;
 
 
-- Top 5 least-engaged customers
SELECT c.contactLastName, c.contactFirstName, c.city, c.country,
	   pgc.profit
  FROM customers AS c
  JOIN profit_generated_per_customer AS pgc
    ON c.customerNumber = pgc.customerNumber
 ORDER BY pgc.profit 
 LIMIT 5;
 
 /* Q3) How Much Can We Spend on Acquiring New Customers */

 -- Customer Lifetime Value (LTV)
 SELECT ROUND(AVG(profit),2) AS avg_profit_ltv
   FROM profit_generated_per_customer;
   
/*
We can conclude that Vintage cars and motorcycles should be top priority for restoking — being the highest-performing products.
The LTV (Customer Lifetime Value), shows us how much profit an average customer generates during their lifetime with the store.
We can use it to predict the stores future profit. 
The current LTV is $39,039. So if theres ten new customers, the store should earn $390,395.
We can use this prediction to decide how much should be spent to aquire new customers.
*/