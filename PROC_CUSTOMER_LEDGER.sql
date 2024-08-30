drop procedure if Exists PROC_CUSTOMER_LEDGER;
DELIMITER $$
CREATE PROCEDURE `PROC_CUSTOMER_LEDGER`( P_CUSTOMER_ID TEXT,
								        P_ENTRY_DATE_FROM TEXT,
									    P_ENTRY_DATE_TO TEXT,
									    P_FORM_TYPE TEXT,
									    P_START INT,
									    P_LENGTH INT,
                                        P_COMPANY_ID INT )
BEGIN

	DECLARE BEGININGBALANCE DECIMAL(22, 2) DEFAULT 0;

	IF P_FORM_TYPE = "" THEN
		SET P_FORM_TYPE = '-1';
    END IF;
    
    -- =========== Beginning Balance ===========

	SELECT CASE 
				WHEN ENTRY_DATE IS NOT NULL THEN IFNULL(SUM(BALANCE), 0)
				ELSE IFNULL(SUM(DEBIT), 0) - IFNULL(SUM(CREDIT), 0)
		   END AS BALANCE INTO BEGININGBALANCE
	  FROM (SELECT CUSTOMER_ID, 
				   ENTRY_DATE, 
                   PAYPAL_TRANSACTION_ID, 
                   FLAG, 
                   FORM, 
                   DEBIT, 
                   CREDIT, 
                   FINAL,
				   SUM(FINAL) OVER (PARTITION BY CUSTOMER_ID ORDER BY CUSTOMER_ID, ENTRY_DATE, PAYPAL_TRANSACTION_ID, FLAG, FORM, DEBIT, CREDIT, FINAL) AS BALANCE
			  FROM ( SELECT B.CUSTOMER_ID, 
							A.SI_ENTRY_DATE AS ENTRY_DATE, 
							A.PAYPAL_TRANSACTION_ID, 
							'V' AS FLAG, 
							'Sale Invoice' AS FORM,
							SUM(A.SI_TOTAL) AS DEBIT,
							NULL AS CREDIT,
							SUM(A.SI_TOTAL) AS FINAL
					   FROM SALE_INVOICE A,
							CUSTOMER B
					  WHERE A.CUSTOMER_ID = B.ID
						AND CASE
							   WHEN P_ENTRY_DATE_FROM <> "" THEN A.SI_ENTRY_DATE < P_ENTRY_DATE_FROM
							   ELSE TRUE
							END
						AND CASE
							   WHEN P_CUSTOMER_ID <> "" THEN B.ID = P_CUSTOMER_ID
							   ELSE TRUE
							END
						AND CASE
							   WHEN P_COMPANY_ID <> "" THEN A.COMPANY_ID = P_COMPANY_ID
							   ELSE TRUE
							END
				   GROUP BY B.CUSTOMER_ID, A.SI_ENTRY_DATE, A.PAYPAL_TRANSACTION_ID
						 
					 UNION ALL 
				   
					 SELECT B.CUSTOMER_ID, 
							A.ST_ENTRY_DATE AS ENTRY_DATE, 
							A.ST_ID AS PAYPAL_TRANSACTION_ID, 
							'C' AS FLAG, 
							'Stock Out' AS FORM,
							SUM(A.ST_TOTAL) AS DEBIT,
							NULL AS CREDIT,
							SUM(A.ST_TOTAL) AS FINAL
					   FROM VW_STOCK_TRANSFER A,
							CUSTOMER B
					  WHERE A.CUSTOMER_ID = B.ID
						AND CASE
							   WHEN P_ENTRY_DATE_FROM <> "" THEN A.ST_ENTRY_DATE < P_ENTRY_DATE_FROM
							   ELSE TRUE
							END
						AND CASE
							   WHEN P_CUSTOMER_ID <> "" THEN B.ID = P_CUSTOMER_ID
							   ELSE TRUE
							END
						AND CASE
							   WHEN P_COMPANY_ID <> "" THEN A.COMPANY_FROM_ID = P_COMPANY_ID
							   ELSE TRUE
							END
				   GROUP BY B.CUSTOMER_ID, A.ST_ENTRY_DATE, A.ST_ID
						  
					 UNION ALL
					
					 SELECT B.CUSTOMER_ID, 
							A.PS_ENTRY_DATE AS ENTRY_DATE, 
							A.PAYPAL_TRANSACTION_ID, 
							'P' AS FLAG,
							'Payment Sent' AS FORM,
							SUM(A.AMOUNT) AS DEBIT,
							NULL AS CREDIT,
							SUM(A.AMOUNT) AS FINAL
					   FROM PAYMENT_SENT A,
							CUSTOMER B
					  WHERE A.CUSTOMER_ID = B.ID
						AND CASE
							   WHEN P_ENTRY_DATE_FROM <> "" THEN A.PS_ENTRY_DATE < P_ENTRY_DATE_FROM
							   ELSE TRUE
							END
						AND CASE
							   WHEN P_CUSTOMER_ID <> "" THEN B.ID = P_CUSTOMER_ID
							   ELSE TRUE
							END
						AND CASE
							   WHEN P_COMPANY_ID <> "" THEN A.COMPANY_ID = P_COMPANY_ID
							   ELSE TRUE
							END
				   GROUP BY B.CUSTOMER_ID, A.PS_ENTRY_DATE, A.PAYPAL_TRANSACTION_ID
						  
					 UNION ALL 
					
					 SELECT B.CUSTOMER_ID, 
							A.PC_ENTRY_DATE AS ENTRY_DATE, 
							A.PAYPAL_TRANSACTION_ID, 
							'R' AS FLAG, 
							'Partial Credit' AS FORM,
							NULL AS DEBIT,
							SUM(A.TOTAL_AMOUNT) AS CREDIT,
							SUM(A.TOTAL_AMOUNT * -1) AS FINAL
					   FROM PARTIAL_CREDIT A,
							CUSTOMER B
					  WHERE A.CUSTOMER_ID = B.ID
						AND  CASE
							   WHEN P_ENTRY_DATE_FROM <> "" THEN A.PC_ENTRY_DATE < P_ENTRY_DATE_FROM
							   ELSE TRUE
							END
						AND CASE
							   WHEN P_CUSTOMER_ID <> "" THEN B.ID = P_CUSTOMER_ID
							   ELSE TRUE
							END
						AND CASE
							   WHEN P_COMPANY_ID <> "" THEN A.COMPANY_ID = P_COMPANY_ID
							   ELSE TRUE
							END
				   GROUP BY B.CUSTOMER_ID, A.PC_ENTRY_DATE, A.PAYPAL_TRANSACTION_ID
						  
					 UNION ALL 
				   
					 SELECT B.CUSTOMER_ID, 
							A.SR_ENTRY_DATE AS ENTRY_DATE, 
							A.PAYPAL_TRANSACTION_ID, 
							'Q' AS FLAG, 
							'Sale Return' AS FORM,
							NULL AS DEBIT,
							SUM(A.SR_TOTAL) AS CREDIT,
							SUM(A.SR_TOTAL * -1) AS FINAL
					   FROM SALE_RETURN A,
							CUSTOMER B
					  WHERE A.CUSTOMER_ID = B.ID
						AND  CASE
							   WHEN P_ENTRY_DATE_FROM <> "" THEN A.SR_ENTRY_DATE < P_ENTRY_DATE_FROM
							   ELSE TRUE
							END
						AND CASE
							   WHEN P_CUSTOMER_ID <> "" THEN B.ID = P_CUSTOMER_ID
							   ELSE TRUE
							END
						AND CASE
							   WHEN P_COMPANY_ID <> "" THEN A.COMPANY_ID = P_COMPANY_ID
							   ELSE TRUE
							END
				   GROUP BY B.CUSTOMER_ID, A.SR_ENTRY_DATE, A.PAYPAL_TRANSACTION_ID
						  
					 UNION ALL

					 SELECT B.CUSTOMER_ID, 
							A.RM_ENTRY_DATE AS ENTRY_DATE, 
							A.PAYPAL_TRANSACTION_ID, 
							'M' AS FLAG, 
							'Receive Money' AS FORM,
							NULL AS DEBIT,
							SUM(A.AMOUNT) AS CREDIT,
							SUM(A.AMOUNT * -1) AS FINAL
					   FROM RECEIVE_MONEY A,
							CUSTOMER B
					  WHERE A.CUSTOMER_ID = B.ID
						AND  CASE
							   WHEN P_ENTRY_DATE_FROM <> "" THEN A.RM_ENTRY_DATE < P_ENTRY_DATE_FROM
							   ELSE TRUE
							END
						AND CASE
							   WHEN P_CUSTOMER_ID <> "" THEN B.ID = P_CUSTOMER_ID
							   ELSE TRUE
							END
						AND CASE
							   WHEN P_COMPANY_ID <> "" THEN A.COMPANY_ID = P_COMPANY_ID
							   ELSE TRUE
							END
				   GROUP BY B.CUSTOMER_ID, A.RM_ENTRY_DATE, A.PAYPAL_TRANSACTION_ID
						  
					 UNION ALL

					 SELECT B.CUSTOMER_ID, 
							A.REP_ENTRY_DATE AS ENTRY_DATE, 
							A.PAYPAL_TRANSACTION_ID, 
							'X' AS FLAG, 
							'Replacement Issue' AS FORM,
							SUM(A.BALANCE) AS DEBIT,
							NULL AS CREDIT,
							SUM(A.BALANCE) AS FINAL
					   FROM REPLACEMENT A,
							CUSTOMER B
					  WHERE A.BALANCE >= 0
						AND A.CUSTOMER_ID = B.ID
						AND CASE
							   WHEN P_ENTRY_DATE_FROM <> "" THEN A.REP_ENTRY_DATE < P_ENTRY_DATE_FROM
							   ELSE TRUE
							END
						AND CASE
							   WHEN P_CUSTOMER_ID <> "" THEN B.ID = P_CUSTOMER_ID
							   ELSE TRUE
							END
						AND CASE
							   WHEN P_COMPANY_ID <> "" THEN A.COMPANY_ID = P_COMPANY_ID
							   ELSE TRUE
							END
				   GROUP BY B.CUSTOMER_ID, A.REP_ENTRY_DATE, A.PAYPAL_TRANSACTION_ID
						  
					 UNION ALL

					 SELECT B.CUSTOMER_ID, 
							A.REP_ENTRY_DATE AS ENTRY_DATE, 
							A.PAYPAL_TRANSACTION_ID, 
							'Y' AS FLAG,
							'Replacement Return' AS FORM,
							NULL AS DEBIT,
							SUM(A.BALANCE * -1) AS CREDIT,
							SUM(A.BALANCE) AS FINAL
					   FROM REPLACEMENT A,
							CUSTOMER B
					  WHERE A.BALANCE < 0
						AND A.CUSTOMER_ID = B.ID
						AND CASE
							   WHEN P_ENTRY_DATE_FROM <> "" THEN A.REP_ENTRY_DATE < P_ENTRY_DATE_FROM
							   ELSE TRUE
							END
						AND CASE
							   WHEN P_CUSTOMER_ID <> "" THEN B.ID = P_CUSTOMER_ID
							   ELSE TRUE
							END
						AND CASE
							   WHEN P_COMPANY_ID <> "" THEN A.COMPANY_ID = P_COMPANY_ID
							   ELSE TRUE
							END
				   GROUP BY B.CUSTOMER_ID, A.REP_ENTRY_DATE, A.PAYPAL_TRANSACTION_ID
				   
					 UNION ALL

					 SELECT B.CUSTOMER_ID, 
							A.R_ENTRY_DATE AS ENTRY_DATE, 
							A.REC_REFERENCE, 
							'T' AS FLAG,
							'Customer Receipt' AS FORM,
							CASE 
								WHEN A.REMAINING_AMOUNT < 0 THEN SUM(ABS(A.REMAINING_AMOUNT)) 
								ELSE NULL 
							END AS DEBIT,
							CASE 
								WHEN A.REMAINING_AMOUNT > 0 THEN SUM(ABS(A.REMAINING_AMOUNT)) 
								ELSE NULL  
							END AS CREDIT,
							CASE 
								WHEN A.REMAINING_AMOUNT > 0 THEN SUM(ABS(A.REMAINING_AMOUNT)) 
								ELSE SUM(ABS(A.REMAINING_AMOUNT) * -1)
							END AS FINAL
					   FROM RECEIPTS A,
							CUSTOMER B
					  WHERE A.REMAINING_AMOUNT <> 0
						AND A.CUSTOMER_ID = B.ID
						AND  CASE
							   WHEN P_ENTRY_DATE_FROM <> "" THEN A.R_ENTRY_DATE < P_ENTRY_DATE_FROM
							   ELSE TRUE
							END
						AND CASE
							   WHEN P_CUSTOMER_ID <> "" THEN B.ID = P_CUSTOMER_ID
							   ELSE TRUE
							END
						AND CASE
							   WHEN P_COMPANY_ID <> "" THEN A.COMPANY_ID = P_COMPANY_ID
							   ELSE TRUE
							END
				   GROUP BY B.CUSTOMER_ID, A.R_ENTRY_DATE, A.REC_REFERENCE
				   ) b
			 WHERE CASE
						WHEN P_FORM_TYPE <> "-1" THEN FLAG IN (P_FORM_TYPE)
						ELSE TRUE
				   END
		   ) C
  GROUP BY CUSTOMER_ID;
  
	-- =========== Beginning Balance ===========

    SET @QRY = CONCAT('SELECT FORM_ID,
							  CASE
								 WHEN FORM IS NOT NULL THEN CUSTOMER_ID
								 ELSE NULL
							  END AS Customer,
							  ENTRY_DATE,
							  PAYPAL_TRANSACTION_ID,
							  FORM,
                              Round(cast(SUM(DEBIT) as Decimal(22,2)),2) As DEBIT,
                              Round(cast(SUM(CREDIT)as Decimal(22,2)),2) AS CREDIT,
							  Round(cast(SUM(FINAL) as Decimal(22,2)),2) AS BALANCE,
                              ',BEGININGBALANCE,' as BEG_BAL,
							  COUNT(*) OVER() AS TOTAL_ROWS
					     FROM ( SELECT FORM_ID,
									   CUSTOMER_ID,
									   ENTRY_DATE,
									   PAYPAL_TRANSACTION_ID,
                                       FLAG,
									   FORM,
									   DEBIT,
									   CREDIT,
									   FINAL
								  FROM ( SELECT 
												ID as FORM_ID,
												CUSTOMER_ID, 
											    "" AS ENTRY_DATE, 
											    "" AS PAYPAL_TRANSACTION_ID, 
											    ''X'' AS FLAG, 
											    ''Beginning Balance'' AS FORM,
											    NULL  AS DEBIT,
											    NULL AS CREDIT,
											    SUM(TOTAL_AMOUNT) + IFNULL((\'',BEGININGBALANCE,'\'),0) AS FINAL
										   FROM CUSTOMER
										  WHERE CASE
												   WHEN \'',P_CUSTOMER_ID,'\' <> "" THEN ID = \'',P_CUSTOMER_ID,'\'
												   ELSE TRUE
											    END
									   GROUP BY CUSTOMER_ID, ENTRY_DATE,ID
                                                
                                         UNION ALL
                                         
                                         SELECT A.ID as FORM_ID,
												B.CUSTOMER_ID, 
											    A.SI_ENTRY_DATE AS ENTRY_DATE, 
											    A.PAYPAL_TRANSACTION_ID, 
											    ''V'' AS FLAG, 
											    ''Sale Invoice'' AS FORM,
											    SUM(A.SI_TOTAL) AS DEBIT,
											    NULL AS CREDIT,
											    SUM(A.SI_TOTAL) AS FINAL
										   FROM SALE_INVOICE A,
											    CUSTOMER B
										  WHERE A.CUSTOMER_ID = B.ID
										    AND CASE
												   WHEN \'',P_ENTRY_DATE_FROM,'\' <> "" THEN A.SI_ENTRY_DATE >= \'',P_ENTRY_DATE_FROM,'\'
												   ELSE TRUE
											    END
										    AND CASE
												   WHEN \'',P_ENTRY_DATE_TO,'\' <> "" THEN A.SI_ENTRY_DATE <= \'',P_ENTRY_DATE_TO,'\'
												   ELSE TRUE
											    END
										    AND CASE
												   WHEN \'',P_CUSTOMER_ID,'\' <> "" THEN B.ID = \'',P_CUSTOMER_ID,'\'
												   ELSE TRUE
											    END
											AND CASE
												   WHEN \'',P_COMPANY_ID,'\' <> "" THEN A.COMPANY_ID = \'',P_COMPANY_ID,'\'
												   ELSE TRUE
											    END
									   GROUP BY B.CUSTOMER_ID, A.SI_ENTRY_DATE, A.PAYPAL_TRANSACTION_ID,A.ID
											 
									     UNION ALL 
									   
									     SELECT A.ID as FORM_ID,
												B.CUSTOMER_ID, 
											    A.ST_ENTRY_DATE AS ENTRY_DATE, 
											    A.ST_ID AS PAYPAL_TRANSACTION_ID, 
											    ''C'' AS FLAG, 
											    ''Stock Out'' AS FORM,
											    SUM(A.ST_TOTAL) AS DEBIT,
											    NULL AS CREDIT,
											    SUM(A.ST_TOTAL) AS FINAL
										   FROM VW_STOCK_TRANSFER A,
											    CUSTOMER B
										  WHERE A.CUSTOMER_ID = B.ID
										    AND CASE
												   WHEN \'',P_ENTRY_DATE_FROM,'\' <> "" THEN A.ST_ENTRY_DATE >= \'',P_ENTRY_DATE_FROM,'\'
												   ELSE TRUE
											    END
										    AND CASE
												   WHEN \'',P_ENTRY_DATE_TO,'\' <> "" THEN A.ST_ENTRY_DATE <= \'',P_ENTRY_DATE_TO,'\'
												   ELSE TRUE
											    END
										    AND CASE
												   WHEN \'',P_CUSTOMER_ID,'\' <> "" THEN B.ID = \'',P_CUSTOMER_ID,'\'
												   ELSE TRUE
											    END
											AND CASE
												   WHEN \'',P_COMPANY_ID,'\' <> "" THEN A.COMPANY_FROM_ID = \'',P_COMPANY_ID,'\'
												   ELSE TRUE
											    END
									   GROUP BY B.CUSTOMER_ID, A.ST_ENTRY_DATE, A.ST_ID,A.ID
											  
									     UNION ALL
										
									     SELECT A.ID as FORM_ID,
												B.CUSTOMER_ID, 
											    A.PS_ENTRY_DATE AS ENTRY_DATE, 
											    A.PAYPAL_TRANSACTION_ID, 
											    ''P'' AS FLAG,
											    ''Payment Sent'' AS FORM,
											    SUM(A.AMOUNT) AS DEBIT,
											    NULL AS CREDIT,
											    SUM(A.AMOUNT) AS FINAL
										   FROM PAYMENT_SENT A,
										  	    CUSTOMER B
										  WHERE A.CUSTOMER_ID = B.ID
										    AND CASE
												   WHEN \'',P_ENTRY_DATE_FROM,'\' <> "" THEN A.PS_ENTRY_DATE >= \'',P_ENTRY_DATE_FROM,'\'
												   ELSE TRUE
											    END
										    AND CASE
												   WHEN \'',P_ENTRY_DATE_TO,'\' <> "" THEN A.PS_ENTRY_DATE <= \'',P_ENTRY_DATE_TO,'\'
												   ELSE TRUE
											    END
										    AND CASE
												   WHEN \'',P_CUSTOMER_ID,'\' <> "" THEN B.ID = \'',P_CUSTOMER_ID,'\'
												   ELSE TRUE
											    END
											AND CASE
												   WHEN \'',P_COMPANY_ID,'\' <> "" THEN A.COMPANY_ID = \'',P_COMPANY_ID,'\'
												   ELSE TRUE
											    END
									   GROUP BY B.CUSTOMER_ID, A.PS_ENTRY_DATE, A.PAYPAL_TRANSACTION_ID,A.iD
											  
									     UNION ALL 
										
									     SELECT A.ID as FORM_ID,
												B.CUSTOMER_ID, 
											    A.PC_ENTRY_DATE AS ENTRY_DATE, 
											    A.PAYPAL_TRANSACTION_ID, 
											    ''R'' AS FLAG, 
											    ''Partial Credit'' AS FORM,
											    NULL AS DEBIT,
											    SUM(A.TOTAL_AMOUNT) AS CREDIT,
											    SUM(A.TOTAL_AMOUNT * -1) AS FINAL
										   FROM PARTIAL_CREDIT A,
											    CUSTOMER B
										  WHERE A.CUSTOMER_ID = B.ID
										    AND CASE
												   WHEN \'',P_ENTRY_DATE_FROM,'\' <> "" THEN A.PC_ENTRY_DATE >= \'',P_ENTRY_DATE_FROM,'\'
												   ELSE TRUE
											    END
										    AND CASE
												   WHEN \'',P_ENTRY_DATE_TO,'\' <> "" THEN A.PC_ENTRY_DATE <= \'',P_ENTRY_DATE_TO,'\'
												   ELSE TRUE
											    END
										    AND CASE
												   WHEN \'',P_CUSTOMER_ID,'\' <> "" THEN B.ID = \'',P_CUSTOMER_ID,'\'
												   ELSE TRUE
											    END
											AND CASE
												   WHEN \'',P_COMPANY_ID,'\' <> "" THEN A.COMPANY_ID = \'',P_COMPANY_ID,'\'
												   ELSE TRUE
											    END
									   GROUP BY B.CUSTOMER_ID, A.PC_ENTRY_DATE, A.PAYPAL_TRANSACTION_ID,A.ID
											  
									     UNION ALL 
									   
									     SELECT A.ID as FORM_ID,
												B.CUSTOMER_ID, 
											    A.SR_ENTRY_DATE AS ENTRY_DATE, 
											    A.PAYPAL_TRANSACTION_ID, 
											    ''Q'' AS FLAG, 
											    ''Sale Return'' AS FORM,
											    NULL AS DEBIT,
											    SUM(A.SR_TOTAL) AS CREDIT,
											    SUM(A.SR_TOTAL * -1) AS FINAL
										   FROM SALE_RETURN A,
											    CUSTOMER B
										  WHERE A.CUSTOMER_ID = B.ID
										    AND CASE
												   WHEN \'',P_ENTRY_DATE_FROM,'\' <> "" THEN A.SR_ENTRY_DATE >= \'',P_ENTRY_DATE_FROM,'\'
												   ELSE TRUE
											    END
										    AND CASE
												   WHEN \'',P_ENTRY_DATE_TO,'\' <> "" THEN A.SR_ENTRY_DATE <= \'',P_ENTRY_DATE_TO,'\'
												   ELSE TRUE
											    END
										    AND CASE
												   WHEN \'',P_CUSTOMER_ID,'\' <> "" THEN B.ID = \'',P_CUSTOMER_ID,'\'
												   ELSE TRUE
											    END
											AND CASE
												   WHEN \'',P_COMPANY_ID,'\' <> "" THEN A.COMPANY_ID = \'',P_COMPANY_ID,'\'
												   ELSE TRUE
											    END
									   GROUP BY B.CUSTOMER_ID, A.SR_ENTRY_DATE, A.PAYPAL_TRANSACTION_ID,A.ID
											  
									     UNION ALL

									     SELECT A.ID as FORM_ID,
												B.CUSTOMER_ID, 
											    A.RM_ENTRY_DATE AS ENTRY_DATE, 
											    A.PAYPAL_TRANSACTION_ID, 
											    ''M'' AS FLAG, 
											    ''Receive Money'' AS FORM,
											    NULL AS DEBIT,
											    SUM(A.AMOUNT) AS CREDIT,
											    SUM(A.AMOUNT * -1) AS FINAL
										   FROM RECEIVE_MONEY A,
											    CUSTOMER B
										  WHERE A.CUSTOMER_ID = B.ID
										    AND CASE
												   WHEN \'',P_ENTRY_DATE_FROM,'\' <> "" THEN A.RM_ENTRY_DATE >= \'',P_ENTRY_DATE_FROM,'\'
												   ELSE TRUE
											    END
										    AND CASE
												   WHEN \'',P_ENTRY_DATE_TO,'\' <> "" THEN A.RM_ENTRY_DATE <= \'',P_ENTRY_DATE_TO,'\'
												   ELSE TRUE
											    END
										    AND CASE
												   WHEN \'',P_CUSTOMER_ID,'\' <> "" THEN B.ID = \'',P_CUSTOMER_ID,'\'
												   ELSE TRUE
											    END
											AND CASE
												   WHEN \'',P_COMPANY_ID,'\' <> "" THEN A.COMPANY_ID = \'',P_COMPANY_ID,'\'
												   ELSE TRUE
											    END
									   GROUP BY B.CUSTOMER_ID, A.RM_ENTRY_DATE, A.PAYPAL_TRANSACTION_ID,A.ID
											  
									     UNION ALL

									     SELECT A.ID as FORM_ID,
												B.CUSTOMER_ID, 
											    A.REP_ENTRY_DATE AS ENTRY_DATE, 
											    A.PAYPAL_TRANSACTION_ID, 
											    ''X'' AS FLAG, 
											    ''Replacement Issue'' AS FORM,
											    SUM(A.BALANCE) AS DEBIT,
											    NULL AS CREDIT,
											    SUM(A.BALANCE) AS FINAL
										   FROM REPLACEMENT A,
											    CUSTOMER B
										  WHERE A.BALANCE >= 0
										    AND A.CUSTOMER_ID = B.ID
										    AND CASE
												   WHEN \'',P_ENTRY_DATE_FROM,'\' <> "" THEN A.REP_ENTRY_DATE >= \'',P_ENTRY_DATE_FROM,'\'
												   ELSE TRUE
											    END
										    AND CASE
												   WHEN \'',P_ENTRY_DATE_TO,'\' <> "" THEN A.REP_ENTRY_DATE <= \'',P_ENTRY_DATE_TO,'\'
												   ELSE TRUE
											    END
										    AND CASE
												   WHEN \'',P_CUSTOMER_ID,'\' <> "" THEN B.ID = \'',P_CUSTOMER_ID,'\'
												   ELSE TRUE
											    END
											AND CASE
												   WHEN \'',P_COMPANY_ID,'\' <> "" THEN A.COMPANY_ID = \'',P_COMPANY_ID,'\'
												   ELSE TRUE
											    END
									   GROUP BY B.CUSTOMER_ID, A.REP_ENTRY_DATE, A.PAYPAL_TRANSACTION_ID,A.ID
											  
									     UNION ALL

									     SELECT A.ID as FORM_ID,
												B.CUSTOMER_ID, 
											    A.REP_ENTRY_DATE AS ENTRY_DATE, 
											    A.PAYPAL_TRANSACTION_ID, 
											    ''Y'' AS FLAG,
											    ''Replacement Return'' AS FORM,
											    NULL AS DEBIT,
											    SUM(A.BALANCE * -1) AS CREDIT,
											    SUM(A.BALANCE) AS FINAL
										   FROM REPLACEMENT A,
											    CUSTOMER B
										  WHERE A.BALANCE < 0
										    AND A.CUSTOMER_ID = B.ID
										    AND CASE
												   WHEN \'',P_ENTRY_DATE_FROM,'\' <> "" THEN A.REP_ENTRY_DATE >= \'',P_ENTRY_DATE_FROM,'\'
												   ELSE TRUE
											    END
										    AND CASE
												   WHEN \'',P_ENTRY_DATE_TO,'\' <> "" THEN A.REP_ENTRY_DATE <= \'',P_ENTRY_DATE_TO,'\'
												   ELSE TRUE
											    END
										    AND CASE
												   WHEN \'',P_CUSTOMER_ID,'\' <> "" THEN B.ID = \'',P_CUSTOMER_ID,'\'
												   ELSE TRUE
											    END
											AND CASE
												   WHEN \'',P_COMPANY_ID,'\' <> "" THEN A.COMPANY_ID = \'',P_COMPANY_ID,'\'
												   ELSE TRUE
											    END
									   GROUP BY B.CUSTOMER_ID, A.REP_ENTRY_DATE, A.PAYPAL_TRANSACTION_ID,A.ID
                                       
                                         UNION ALL

									     SELECT A.ID as FORM_ID,
												B.CUSTOMER_ID, 
											    A.R_ENTRY_DATE AS ENTRY_DATE, 
											    A.REC_REFERENCE, 
											    ''T'' AS FLAG,
											    ''Customer Receipt'' AS FORM,
                                                CASE 
													WHEN A.REMAINING_AMOUNT < 0 THEN SUM(ABS(A.REMAINING_AMOUNT)) 
													ELSE NULL 
                                                END AS DEBIT,
												CASE 
													WHEN A.REMAINING_AMOUNT > 0 THEN SUM(ABS(A.REMAINING_AMOUNT)) 
													ELSE NULL  
                                                END AS CREDIT,
												CASE 
													WHEN A.REMAINING_AMOUNT > 0 THEN SUM(ABS(A.REMAINING_AMOUNT) * -1) 
													ELSE SUM(ABS(A.REMAINING_AMOUNT))
                                                END AS FINAL
										   FROM RECEIPTS A,
											    CUSTOMER B
										  WHERE A.REMAINING_AMOUNT <> 0
										    AND A.CUSTOMER_ID = B.ID
										    AND CASE
												   WHEN \'',P_ENTRY_DATE_FROM,'\' <> "" THEN A.R_ENTRY_DATE >= \'',P_ENTRY_DATE_FROM,'\'
												   ELSE TRUE
											    END
										    AND CASE
												   WHEN \'',P_ENTRY_DATE_TO,'\' <> "" THEN A.R_ENTRY_DATE <= \'',P_ENTRY_DATE_TO,'\'
												   ELSE TRUE
											    END
										    AND CASE
												   WHEN \'',P_CUSTOMER_ID,'\' <> "" THEN B.ID = \'',P_CUSTOMER_ID,'\'
												   ELSE TRUE
											    END
											AND CASE
												   WHEN \'',P_COMPANY_ID,'\' <> "" THEN A.COMPANY_ID = \'',P_COMPANY_ID,'\'
												   ELSE TRUE
											    END
									   GROUP BY B.CUSTOMER_ID, A.R_ENTRY_DATE, A.REC_REFERENCE,A.ID
									   ) C
							     WHERE CASE
										  WHEN \'',P_FORM_TYPE,'\' <> "-1" THEN FLAG IN (',P_FORM_TYPE,')
										  ELSE TRUE
									   END
							  ) Z
							  GROUP BY FORM_ID,
									   CUSTOMER_ID,
									   ENTRY_DATE,
									   PAYPAL_TRANSACTION_ID,
                                       FLAG,
									   FORM WITH ROLLUP
									   having Form_Id is null or FORM is not null LIMIT ',P_START,', ',P_LENGTH,';');
    PREPARE STMP FROM @QRY;
    EXECUTE STMP ;
    DEALLOCATE PREPARE STMP;
END $$
DELIMITER ;
