/*
- The products table contains information on all the products available for sale, with a total of 110 unique entries
- The product lines table contains a list of product line categories, totaling 7
- The customers table contains information about the customers and their contact persons, with a total of 122 entries
- The employees table contains information about the employees who sold the vehicles, totaling 23 employees
- The offices table contains information about the sales offices, with a total of 7 entries
-The orders table contains information about the customers' sales orders, with a total of 326 entries
- The orderdetails table contains information about the sales order line for each sales order, with a total of 2996 entries
- The payments table contains information about the customers' payment methods, with a total of 273 entries

-- Table Relationships:
-- 1. The productLines table is connected to the products table via the productLine column.
-- 2. The products table is connected to the orderDetails table via the productCode column.
-- 3. The orderDetails table is connected to the orders table via the orderNumber column.
-- 4. The orders table is connected to the customers table via the customerNumber column.
-- 5. The customers table is connected to the payments table via the customerNumber columns.
-- 6. The customers table is connected to the employees table via the salesRepEmployeeNumber column.
-- 7. The employees table is connected to the offices table via the officeCode column.
*/

SELECT "Products" AS table_name,
(SELECT COUNT(*)
 FROM pragma_table_info('products')) AS number_of_attributes,
(SELECT COUNT (*)
 FROM products) AS number_of_rows
 
UNION ALL  
 
 SELECT "ProductLines" AS table_name,
(SELECT COUNT(*)
 FROM pragma_table_info('productLines')) AS number_of_attributes,
(SELECT COUNT (*)
 FROM ProductLines) AS number_of_rows
 
UNION ALL 

SELECT "Orders" AS table_name,
(SELECT COUNT(*)
 FROM pragma_table_info('orders')) AS number_of_attributes, 
(SELECT COUNT (*)
 FROM orders) AS number_of_rows
 
 
 UNION ALL 
 
 SELECT "OrderDetails" AS table_name,
(SELECT COUNT(*)
 FROM pragma_table_info('orderDetails')) AS number_of_attributes, 
(SELECT COUNT (*)
 FROM products) AS number_of_rows
 
 
 UNION ALL 
 
 SELECT "Payments" AS table_name,
(SELECT COUNT(*)
 FROM pragma_table_info('payments')) AS number_of_attributes, 
(SELECT COUNT (*)
 FROM payments) AS number_of_rows
 
 UNION ALL 
 
 SELECT "Employees" AS table_name,
(SELECT COUNT(*)
 FROM pragma_table_info('Employees')) AS number_of_attributes,
(SELECT COUNT (*)
 FROM employees) AS number_of_rows
 
 
 UNION ALL 
 
 SELECT "Offices" AS table_name,
(SELECT COUNT(*)
 FROM pragma_table_info('offices')) AS number_of_attributes,
(SELECT COUNT (*)
 FROM offices) AS number_of_rows;
 

/*--Prioriy products for restocking 
-- Priority products for restocking was found out as the products that have high performance and in the brink of being out of stock .
--low_stock = SUM( quantityOrdered)/quantityInStock
--product_performance= SUM(quantityOrdered * priceEach) 
--In order to find this products and orderdetails tables are joined using correlated query, this can also be done using a INNER JOIN */

WITH 
low_stock AS(

SELECT p.productName, p.productCode,p.productLine,
(SELECT ROUND(SUM(od.quantityOrdered)/p.quantityInStock*1.0,2)
 FROM orderdetails AS od 
 WHERE od.productCode=p.productCode)AS refill
 FROM products AS p 
 GROUP BY productCode
 ORDER BY refill DESC
 LIMIT 10
 ),

product_performance AS(
SELECT od.productCode,SUM(quantityOrdered*priceEach) AS product_sales
FROM orderdetails AS od
GROUP BY productCode
ORDER BY product_sales DESC   
LIMIT 10
)

SELECT s.productName,s.productLine
FROM low_stock AS s
WHERE s.productCode IN ( SELECT productCode
														  FROM product_performance)
                         
LIMIT 10;    

-- Top 5 VIP customers

WITH 
customer_profit AS (
SELECT o.customerNumber, SUM(quantityOrdered * (priceEach - buyPrice)) AS profit
	FROM products AS p
	JOIN orderdetails AS od
		 ON p.productCode = od.productCode
	JOIN orders AS o
		 ON o.orderNumber = od.orderNumber
	GROUP BY o.customerNumber
)

SELECT contactLastName, contactFirstName, city, country, cp.profit
	FROM customers AS c
     JOIN customer_profit AS cp
		ON cp.customerNumber = c.customerNumber
	ORDER BY cp.profit DESC
	LIMIT 5;

-- Least 5 VIP customers

WITH 
customer_profit AS (
SELECT o.customerNumber, SUM(quantityOrdered * (priceEach - buyPrice)) AS profit
	FROM products AS p
	JOIN orderdetails AS od
		 ON p.productCode = od.productCode
	JOIN orders AS o
		 ON o.orderNumber = od.orderNumber
	GROUP BY o.customerNumber
)

SELECT contactLastName, contactFirstName, city, country, cp.profit
	FROM customers AS c
     JOIN customer_profit AS cp
		ON cp.customerNumber = c.customerNumber
	ORDER BY cp.profit 
	LIMIT 5;


WITH 

payment_with_year_month_table AS (
SELECT *, 
       CAST(SUBSTR(paymentDate, 1,4) AS INTEGER)*100 + CAST(SUBSTR(paymentDate, 6,7) AS INTEGER) AS year_month
  FROM payments p
),

customers_by_month_table AS (
SELECT p1.year_month, COUNT(*) AS number_of_customers, SUM(p1.amount) AS total
  FROM payment_with_year_month_table p1
 GROUP BY p1.year_month
),

new_customers_by_month_table AS (
SELECT p1.year_month, 
       COUNT(DISTINCT customerNumber) AS number_of_new_customers,
       SUM(p1.amount) AS new_customer_total,
       (SELECT number_of_customers
          FROM customers_by_month_table c
        WHERE c.year_month = p1.year_month) AS number_of_customers,
       (SELECT total
          FROM customers_by_month_table c
         WHERE c.year_month = p1.year_month) AS total
  FROM payment_with_year_month_table p1
 WHERE p1.customerNumber NOT IN (SELECT customerNumber
                                   FROM payment_with_year_month_table p2
                                  WHERE p2.year_month < p1.year_month)
 GROUP BY p1.year_month
)

SELECT year_month, 
       ROUND(number_of_new_customers*100/number_of_customers,1) AS number_of_new_customers_props,
       ROUND(new_customer_total*100/total,1) AS new_customers_total_props
  FROM new_customers_by_month_table;

WITH 
customer_profit AS (
SELECT o.customerNumber, SUM(quantityOrdered * (priceEach - buyPrice)) AS profit
	FROM products AS p
	JOIN orderdetails AS od
		 ON p.productCode = od.productCode
	JOIN orders AS o
		 ON o.orderNumber = od.orderNumber
	GROUP BY o.customerNumber
)

SELECT AVG(profit) AS avg_profit
	FROM customer_profit;



/* Upon analysis, it's evident that the "Classic cars" product line boasts the highest performance despite maintaining a modest stock level.
 The 1968 Ford Mustang emerges as the most in-demand product, indicating significant market interest. 
 Notably, the top five VIP customers hail from Spain, USA, Australia, and France, showcasing a diverse customer base. 
 Among these, the top two VIP customers have generated profits exceeding $200,000, substantially surpassing the profits of the subsequent top three VIP customers, which range between $60,000 and $73,000. 
 Conversely, customers from the USA, Italy, France, and the UK display lower levels of engagement, with the least profitable customer generating below $3,000. 
 Consequently, the company has achieved an average profit of $39,039.594388 per customer in their Lifetime Value (LTV). 
 Considering these findings, investing in customer acquisition strategies could lead to increased profitability, especially by prioritizing factors such as the country with the highest sales and the most lucrative year-month periods. */





 
 