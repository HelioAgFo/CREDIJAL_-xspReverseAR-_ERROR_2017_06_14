USE [FINANCIERAAPP]
GO
/****** Object:  StoredProcedure [dbo].[XSP_AUCORTESERVAR_CM]    Script Date: 14/06/2017 12:08:41 p.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROC [dbo].[XSP_AUCORTESERVAR_CM] 
------- ARDOC -----------
@PerPost VARCHAR(6),
@DocType VARCHAR(2),
@Fecha VARCHAR(10),
@UserId VARCHAR(10),
@CpnyId VARCHAR(10),
@Tipo VARCHAR(1) ,
@IDOportunity varchar(50)
AS
--SET @PerPost = '201604'
--SET @UserId = 'SYSADMIN'
--SET @DocType = 'IN'
-----------------------------
SET NOCOUNT ON
	
	-------- RUNNING ASSIGNED FOR ALL DEVELOPMENT-------------------
	DECLARE @PerEnt VARCHAR(6)
	DECLARE @BatNbr VARCHAR(10)
	DECLARE @LastBatNbr VARCHAR(10)
	DECLARE @DRCR VARCHAR(2)
	DECLARE @FiscYr VARCHAR(4)
	DECLARE @LineId INTEGER
	DECLARE @LineNbr INTEGER
	DECLARE @DocBal2 FLOAT
	DECLARE @CuryDocBal2 FLOAT
	DECLARE @DocBal3 FLOAT
	DECLARE @CuryDocBal3 FLOAT
	
	-------- FETCH ASSIGNED FOR BATCH -------------------
	DECLARE @DocDate VARCHAR(10)
	DECLARE @SucursalID VARCHAR(10)
	DECLARE @LedgerId VARCHAR(10)
	DECLARE	@CuryId VARCHAR(5)
	DECLARE @ControlOrdServ INTEGER
	DECLARE @CtrlTot FLOAT
	
	-------- FETCH ASSIGNED FOR ARDOC -------------------
	DECLARE @RefNbr VARCHAR(10)
	DECLARE @ARAcct VARCHAR(10)
	DECLARE @ARSub VARCHAR(10)
	DECLARE @DocBal FLOAT
	DECLARE @DocBalPrueba FLOAT
	DECLARE @CuryTxblTot00 FLOAT
	DECLARE @CustId VARCHAR(10)
	DECLARE @ServiceCallId VARCHAR(15)
	DECLARE @DueDate DATETIME
	DECLARE @SlsPerId VARCHAR(10)
	DECLARE @TaxId00 VARCHAR(10)
	DECLARE @TaxTot00 FLOAT
	DECLARE @TermsId VARCHAR(2)
	DECLARE @TxblTot00 FLOAT
	DECLARE @NumContrato VARCHAR(10)
	DECLARE @Docto VARCHAR(6)
	DECLARE @Plazo VARCHAR(3)
	DECLARE @Anexo VARCHAR(30)
	DECLARE @TipoCredito VARCHAR(30)
	DECLARE @TipoCreditoCompleto VARCHAR(30)
	DECLARE @IvaCXC FLOAT
	DECLARE @FechaPago VARCHAR(10)
	

	
	-------- FETCH ASSIGNED FOR ARTRAN -------------------
	DECLARE @SlsAcct VARCHAR(10)

	DECLARE @ExtRefNbr VARCHAR(10)
	DECLARE @InvtId VARCHAR(30)
	DECLARE @Qty FLOAT
	DECLARE @SlsSub VARCHAR(10)
	
	-- CAPITAL
	DECLARE @CuryTranAmt FLOAT
	DECLARE @CuryUnitPrice FLOAT
	DECLARE @TranAmt FLOAT
	DECLARE @UnitPrice FLOAT
	-- INTERESES 
	DECLARE @CuryTranAmtI FLOAT
	DECLARE @CuryUnitPriceI FLOAT
	DECLARE @TranAmtI FLOAT
	DECLARE @UnitPriceI FLOAT
	-- IVA 
	DECLARE @CuryTranAmtIV FLOAT
	DECLARE @CuryUnitPriceIV FLOAT
	DECLARE @TranAmtIV FLOAT
	DECLARE @UnitPriceIV FLOAT
	-- LOCALIZADOR
	DECLARE @CuryTranAmtL FLOAT
	DECLARE @CuryUnitPriceL FLOAT
	DECLARE @TranAmtL FLOAT
	DECLARE @UnitPriceL FLOAT
	
	--------- BEGIN ------------------
	SET @PerEnt = @PerPost
	SET @DRCR = CASE WHEN @DocType IN ('IN', 'AD') THEN 'C' ELSE 'D' END
	SET @FiscYr = LEFT(@PerPost, 4)
	SET @LineId = 0
	SET @LineNbr  = -32678
	
	--IF (@DOCTYPE = 'IN' )
	--BEGIN SET @DOCTO = 'NX12' END 
	--ELSE 
	--BEGIN SET @DOCTO = 'NX07' END
	
	--SET @Anexo = 'B'

	---------BEGIN CURSOR FOR BATCH ------------------
	BEGIN TRANSACTION
	BEGIN TRY
	-- ********************************************************************
		DECLARE Batch_Cursor CURSOR FOR

		SELECT CONVERT(VARCHAR(10), AUCorteServ.DocDate2, 101), AUCorteServ.CpnyId, 
				AUCorteServ.SucursalId, GLSetup.LedgerID, GLSetup.BaseCuryId,
				COUNT(DISTINCT AUCorteServ.ServiceCallId), 
				LTRIM(STR(SUM(AUCorteServ.Pago), 25, 2))
		FROM AUCorteServ INNER JOIN GLSetup ON
				AUCorteServ.CpnyID = GLSetup.CpnyId
			INNER JOIN Customer ON
				AUCorteServ.CustID = Customer.CustId
			INNER JOIN SalesTax ON
				Customer.TaxID00 = SalesTax.TaxId
		WHERE AUCorteServ.RefNbr != '' AND 
 			CONVERT(VARCHAR(4), YEAR(CONVERT(VARCHAR(10), AUCorteServ.DocDate2, 101)), 0) + '' + 
 				RIGHT(CONVERT(VARCHAR(3), 100 + MONTH(CONVERT(VARCHAR(10), AUCorteServ.DocDate2, 101)), 0), 2) = @PerPost AND
 			AUCorteServ.ARBatNbr = '' and CONVERT(VARCHAR(10), AUCorteServ.DocDate2, 101) = @Fecha AND
 			AUCorteServ.SUCURSALID = @CpnyId AND
			AUCORTESERV.SERVICECALLID = @IDOportunity
		GROUP BY CONVERT(VARCHAR(10), AUCorteServ.DocDate2, 101), AUCorteServ.CpnyId, AUCorteServ.SucursalId, GLSetup.LedgerID, GLSetup.BaseCuryId, SalesTax.TaxRate
		ORDER BY CONVERT(VARCHAR(10), AUCorteServ.DocDate2, 101), AUCorteServ.CpnyId, AUCorteServ.SucursalId, GLSetup.LedgerID, GLSetup.BaseCuryId, SalesTax.TaxRate

		OPEN Batch_Cursor

		FETCH NEXT FROM Batch_Cursor
		INTO @DocDate, @CpnyId, @SucursalId, @LedgerId, @CuryId, @ControlOrdServ, @CtrlTot

		WHILE @@FETCH_STATUS = 0
		BEGIN
			
				SELECT @LastBatNbr = RTRIM(LastBatNbr) + 1 FROM ARSetup ORDER BY SetupId
				SELECT @BatNbr =  REPLICATE('0',6-LEN(RTRIM(@LastBatNbr))) + RTRIM(@LastBatNbr)
				UPDATE [ARSetup] SET [LastBatNbr] = @BatNbr
				
				INSERT Batch(acct,autorev,autorevcopy,balancetype,bankacct,banksub,basecuryid,batnbr,battype,clearamt,cleared,cpnyid,
								crtd_datetime,crtd_prog,crtd_user,crtot,ctrltot,curycrtot,curyctrltot,curydepositamt,curydrtot,curyeffdate,
								curyid,curymultdiv,curyrate,curyratetype,cycle,dateclr,dateent,depositamt,descr,drtot,editscrnnbr,glpostopt,
								jrnltype,ledgerid,lupd_datetime,lupd_prog,lupd_user,module,nbrcycle,noteid,origbatnbr,origcpnyid,origscrnnbr,
								perent,perpost,rlsed,s4future01,s4future02,s4future03,s4future04,s4future05,s4future06,s4future07,s4future08,
								s4future09,s4future10,s4future11,s4future12,status,sub,user1,user2,user3,user4,user5,user6,user7,user8)  
				VALUES( '', 0, 0, '', '', '', @CuryId, @BatNbr, 'N', 0, 0, @CpnyId, 
						GETDATE(), '08010', @UserId, @CtrlTot, @CtrlTot, @CtrlTot, @CtrlTot, 0, 0, GETDATE(), 
						@CuryId, 'M', 1, '', 0, '01/01/1900 ', GETDATE(), 0, '', 0, '08010', 'D', 
						'AR', @LedgerId, GETDATE(), '08010', 'SYSADMIN', 'AR', 0, 0, '', '', '', 
						@PerEnt, @PerPost, 0, '', '', 0, 0, 0, 0, '01/01/1900 ', '01/01/1900 ', 
						0, 0, '', '', 'H', '', '', '', 0, 0, '', '', '01/01/1900 ', '01/01/1900 ')
				
				
				------------------- BEGIN CURSOR FOR ARDOC -----------------------------
						DECLARE ARDoc_Cursor CURSOR FOR
							SELECT 
									(Select top 1 refnbr from AUCorteServ where ServiceCallId = @IDOportunity order by RefNbr) Refnbr,
									AUCtasServ.ARAcct,
									AUCtasServ.ARSub,
									Round(LTRIM(Convert(decimal(10, 2),SUM(AUCorteServ.Pago))),2),
									Round(LTRIM(Convert(decimal(10, 2),SUM(AUCorteServ.Pago))),2),
									AUCorteServ.CustID, AUCorteServ.ServiceCallID, 
									--DATEADD(DAY, Terms.DueIntrv, 
									DATEADD(DAY, 0, 
									CONVERT(VARCHAR(10), AUCorteServ.DocDate2, 101)),
									'' Asesor, Customer.TaxID00, 
									Round(LTRIM(Convert(decimal(10, 2),SUM(AUCorteServ.Pago))),2),
									Round(LTRIM(Convert(decimal(10, 2),SUM(AUCorteServ.Pago))),2),
									--ISNULL(terms.TermsId, 'A7'),
									'',
									aucorteserv.NumeroContrato,
									CONVERT(VARCHAR(3), AUCorteServ.plazo),
									AUCorteServ.TipoCreditoCompleto,
									AUCorteServ.TipoCredito,
									AUCORTESERV.IvaCXC,
									CONVERT(VARCHAR(10), getdate(), 101)
									FROM AUCorteServ INNER JOIN GLSetup ON
									AUCorteServ.CpnyID = GLSetup.CpnyId
									INNER JOIN Customer ON
									AUCorteServ.CustID = Customer.CustId
									INNER JOIN SalesTax ON
									Customer.TaxID00 = SalesTax.TaxId
									--LEFT OUTER JOIN Terms ON
									--AUCorteServ.PLAZO = Terms.NbrInstall
									LEFT OUTER JOIN AUCtasServ ON 
									AUCorteServ.CpnyID = AUCtasServ.CpnyId
									AND AUCorteServ.TipoCredito = AUCtasServ.CallType
									AND AUCorteServ.TipoVehiculo = AUCtasServ.ClassId
										WHERE AUCorteServ.RefNbr != '' AND 
 									CONVERT(VARCHAR(4), YEAR(CONVERT(VARCHAR(10), AUCorteServ.DocDate2, 101)), 0) + '' + 
 										RIGHT(CONVERT(VARCHAR(3), 100 + MONTH(CONVERT(VARCHAR(10), AUCorteServ.DocDate2, 101)), 0), 2) = @PerPost AND
 									AUCorteServ.ARBatNbr = ''  AND
 									CONVERT(VARCHAR(10), AUCorteServ.DocDate2, 101) = @DocDate AND
 									AUCorteServ.SucursalID = @SucursalID AND
 									AUCorteServ.CpnyID = @CpnyId AND
									AUCORTESERV.SERVICECALLID = @IDOportunity
									GROUP BY --AUCorteServ.RefNbr,
									AUCorteServ.CustID, AUCorteServ.ServiceCallID, 
									--DATEADD(DAY, Terms.DueIntrv, AUCorteServ.DocDate2),
									DATEADD(DAY, 0, AUCorteServ.DocDate2),
									--Customer.TaxID00, SalesTax.TaxRate, Terms.DueIntrv,
									Customer.TaxID00, SalesTax.TaxRate, --0,
									CONVERT(VARCHAR(10), AUCorteServ.DocDate2, 101),
									AUCorteServ.CpnyID, AUCorteServ.SucursalID, 
									--terms.TermsId,
									--0,
									aucorteserv.NumeroContrato,
									AUCorteServ.plazo,
									AUCorteServ.TipoCreditoCompleto,
									AUCtasServ.ARAcct, 
									AUCtasServ.ARSub,
									AUCorteServ.TipoCredito,
									AUCORTESERV.IvaCXC
							ORDER BY CONVERT(VARCHAR(10), AUCorteServ.DocDate2, 101), AUCorteServ.CpnyId, AUCorteServ.SucursalId
							OPEN ARDoc_Cursor
							FETCH NEXT FROM ARDoc_Cursor
							INTO @RefNbr, @ARAcct, @ARSub, @DocBal, @CuryTxblTot00, @CustId, @ServiceCallId, @DueDate, @SlsPerId, @TaxId00, @TaxTot00, @TxblTot00, @TermsId, @NumContrato, @Plazo,@Anexo,@TipoCredito,@IvaCXC,@FechaPago
							WHILE @@FETCH_STATUS = 0
							BEGIN
								Set @TipoCreditoCompleto = @Anexo
								IF (@DOCTYPE = 'IN' )
								 BEGIN SET @DOCTO = 'NX12' END 
								ELSE 
								 BEGIN
								   IF (@Anexo = 'Seguro')
								    BEGIN SET @DOCTO = 'NX08'  END 
								   ELSE
								    BEGIN SET @DOCTO = 'NX07'  END
								 END

								-- Hacer CAST Anexo
								IF (@Anexo = 'Crédito Simple' or @Anexo = 'Crédito Taxi Propietario' or @Anexo = 'Crédito Taxi Arrendatario'
									or @Anexo = 'Crédito Uber' or @Anexo = '8CS' or @Anexo = '9CS'or @Anexo = '10CS' )
								 BEGIN SET @Anexo = 'B' END 
								ELSE  IF (@Anexo = 'Arrendamiento Automotriz' OR @Anexo = '11A' OR @Anexo = '12A' OR @Anexo = '13A')
								 BEGIN SET @Anexo = 'C' END 
								ELSE  IF (@Anexo = 'Arrendamiento Otros Equipos')
								 BEGIN SET @Anexo = 'O' END
								ELSE  IF (@Anexo = 'Seguro')
								 BEGIN SET @Anexo = 'BS' END
								ELSE 
								 BEGIN SET @Anexo = 'B' END
								
								--set @RefNbr = (@NumContrato +'-'+ @DocType +'-'+ @RefNbr)
								SELECT Refnbr FROM RefNbr WHERE RefNbr = @RefNbr
								IF @@ROWCOUNT = 0
								BEGIN
								INSERT  RefNbr(crtd_datetime,crtd_prog,crtd_user,doctype,lupd_datetime,lupd_prog,lupd_user,
												refnbr,s4future01,s4future02,s4future03,s4future04,s4future05,s4future06,s4future07,s4future08,
												s4future09,s4future10,s4future11,s4future12,user1,user2,user3,user4,user5,user6,user7,user8)  
								VALUES( '01/01/1900 ', '', '', '', '01/01/1900 ', '', '', 
												@RefNbr, '', '', 0, 0, 0, 0, '01/01/1900 ', '01/01/1900 ', 
												0, 0, '', '', '', '', 0, 0, '', '', '01/01/1900 ', '01/01/1900 ')
								END
								INSERT ARDoc(acctnbr,agentid,applamt,applbatnbr,applbatseq,asid,bankacct,bankid,banksub,batnbr,
												batseq,cleardate,cmmnamt,cmmnpct,contractid,cpnyid,crtd_datetime,crtd_prog,crtd_user,
												currentnbr,curyapplamt,curyclearamt,curycmmnamt,curydiscapplamt,curydiscbal,curydocbal,curyeffdate,
												curyid,curymultdiv,curyorigdocamt,curyrate,curyratetype,curystmtbal,curytaxtot00,curytaxtot01,curytaxtot02,curytaxtot03,
												curytxbltot00,curytxbltot01,curytxbltot02,curytxbltot03,custid,custordnbr,cycle,discapplamt,discbal,discdate,
												docbal,docclass,docdate,docdesc,doctype,draftissued,duedate,installnbr,jobcntr,linecntr,lupd_datetime,lupd_prog,
												lupd_user,masterdocnbr,nbrcycle,noprtstmt,noteid,opendoc,ordnbr,origbankacct,origbanksub,origcpnyid,origdocamt,origdocnbr,
												pc_status,perclosed,perent,perpost,pmtmethod,projectid,refnbr,rgolamt,rlsed,
												s4future01,s4future02,s4future03,s4future04,s4future05,s4future06,s4future07,s4future08,s4future09,s4future10,s4future11,s4future12,
												servicecallid,shipmentnbr,slsperid,status,stmtbal,stmtdate,taskid,
												taxcntr00,taxcntr01,taxcntr02,taxcntr03,taxid00,taxid01,taxid02,taxid03,taxtot00,taxtot01,taxtot02,taxtot03,
												terms,txbltot00,txbltot01,txbltot02,txbltot03,user1,user2,user3,user4,user5,user6,user7,user8,wsid)  
								VALUES( '', '', 0, '', 0, 0, @ARAcct, '', @ARSub, @BatNbr, 
												0, '01/01/1900 ', 0, 0, '', @CpnyId, GETDATE(), '08010', @UserId, 
												--0, 0, 0, 0, 0, 0, @DocBal+@IvaCXC, GETDATE(), 
												0, 0, 0, 0, 0, 0, @DocBal, GETDATE(), 
												--@CuryId, 'M', @DocBal+@IvaCXC, 1, '', 0, 0, 0, 0, 0, 
												@CuryId, 'M', @DocBal, 1, '', 0, 0, 0, 0, 0, 
												0, 0, 0, 0, @CustId, '', 0, 0, 0, @DocDate, 
												--@DocBal+@IvaCXC, 'N', @DocDate, 'Contrato: '+RTRIM(@NumContrato)+@Anexo + ' Plazo '+@Plazo, @DocType, 0, @FechaPago, 0, 0, 1, GETDATE(), '08010', 
												@DocBal, 'N', @DocDate, 'NC Contrato: '+RTRIM(@NumContrato)+@Anexo + ' Plazo '+@Plazo, @DocType, 0, @FechaPago, 0, 0, 1, GETDATE(), '08010', 
												--@UserId, '', 0, 0, 0, 1, '', '', '', '', @DocBal+@IvaCXC, '', 
												@UserId, '', 0, 0, 0, 1, '', '', '', '', @DocBal, '', 
												--'0', '', @PerEnt, @PerPost, '', '', SUBSTRING ( @ServiceCallId ,2 , 8 ) + @RefNbr, 0, 0, 
												--'0', '', @PerEnt, @PerPost, '', '', (REPLACE ( @NumContrato , '-' , '' )+right(convert(varchar(3),@RefNbr+100),2) + SUBSTRING(@DocType,0,2)), 0, 0, 
												'0', '', @PerEnt, @PerPost, '', '', @RefNbr, 0, 0,
												'', '', 0, 0, 0, 0, '01/01/1900 ', '01/01/1900 ', 0, 0, '', '', 
												SUBSTRING ( @ServiceCallId ,0 , 10 ), 0, @SlsPerId, '', 0, '01/01/1900 ', '', 
												1, 0, 0, 0, @TaxId00, '', '', '', 0, 0, 0, 0, 
												--@TermsId, 0, 0, 0, 0, @DOCTO, '', 0, 0, @NumContrato, @Anexo, '01/01/1900 ', '01/01/1900 ', 0)
												'CO', 0, 0, 0, 0, @DOCTO, '', 0, 0, @NumContrato, @Anexo, '01/01/1900 ', '01/01/1900 ', 0)
								------------------- BEGIN CURSOR FOR ARTRAN -----------------------------
								DECLARE ARTran_Cursor CURSOR FOR
								SELECT --'216101' Acct,
										AUCtasServ.Acct, 
										sum(convert(FLOAT,LTRIM(STR(AUCorteServ.Capital, 25, 2)))),
										0,
										sum(convert(FLOAT,LTRIM(STR(AUCorteServ.Intereses, 25, 2)))),
										0,
										sum(convert(FLOAT,LTRIM(STR(AUCorteServ.Iva, 25, 2)))),
										0,
										sum(convert(FLOAT,LTRIM(STR(AUCorteServ.Localizador, 25, 2)))),
										0,
										'', 
										''InvtId,
										LTRIM(STR(1, 25, 2)),	
										--'0000000' Sub,
										AUCtasServ.Sub,
										sum(convert(FLOAT,LTRIM(STR(AUCorteServ.Capital, 25, 2)))),
										0,
										sum(convert(FLOAT,LTRIM(STR(AUCorteServ.Intereses, 25, 2)))),
										0,
										sum(convert(FLOAT,LTRIM(STR(AUCorteServ.Iva, 25, 2)))),
										0,
										sum(convert(FLOAT,LTRIM(STR(AUCorteServ.Localizador, 25, 2)))),
										0
										FROM AUCorteServ INNER JOIN GLSetup ON
										AUCorteServ.CpnyID = GLSetup.CpnyId
										INNER JOIN Customer ON
										AUCorteServ.CustID = Customer.CustId
										INNER JOIN SalesTax ON
										Customer.TaxID00 = SalesTax.TaxId
										LEFT OUTER JOIN AUCtasServ ON 
										AUCorteServ.CpnyID = AUCtasServ.CpnyId
										AND AUCorteServ.TipoCredito = AUCtasServ.CallType
										AND AUCorteServ.TipoVehiculo = AUCtasServ.ClassId
										WHERE AUCorteServ.RefNbr != '' AND 
										CONVERT(VARCHAR(4), YEAR(CONVERT(VARCHAR(10), AUCorteServ.DocDate2, 101)), 0) + '' + 
										RIGHT(CONVERT(VARCHAR(3), 100 + MONTH(CONVERT(VARCHAR(10), AUCorteServ.DocDate2, 101)), 0), 2) =@PerPost  AND
										AUCorteServ.ARBatNbr = ''  AND
										--AUCorteServ.RefNbr = @RefNbr AND
										AUCORTESERV.SERVICECALLID = @IDOportunity
										group by AUCtasServ.Acct,AUCtasServ.Sub,AUCorteServ.DocDate2,AUCorteServ.CpnyId,AUCorteServ.SucursalId,AUCorteServ.ServiceCallId
										ORDER BY CONVERT(VARCHAR(10), AUCorteServ.DocDate2, 101), AUCorteServ.CpnyId, AUCorteServ.SucursalId, AUCorteServ.ServiceCallId

									OPEN ARTran_Cursor
									FETCH NEXT FROM ARTran_Cursor
									INTO  @SlsAcct, 
									@CuryTranAmt, @CuryUnitPrice,
									@CuryTranAmtI, @CuryUnitPriceI,
									@CuryTranAmtIV, @CuryUnitPriceIV,
									@CuryTranAmtL, @CuryUnitPriceL,
									@ExtRefNbr, @InvtId, @Qty, @SlsSub, 
									@TranAmt, @UnitPrice,
									@TranAmtI, @UnitPriceI,
									@TranAmtIV, @UnitPriceIV,
									@TranAmtL, @UnitPriceL

									SET @LineId = 1
									SET @LineNbr  = -32678
									
									WHILE @@FETCH_STATUS = 0
									BEGIN
									--IF (@TipoCredito = 'Arrendamiento' and ( @TipoCreditoCompleto = 'Arrendamiento Automotriz'or  @TipoCreditoCompleto = 'Arrendamiento Otros Equipos') )
									IF (@TipoCredito = 'Arrendamiento')
									BEGIN 
										-- INSERTA UNA PARTIDA DE ARRENDAMIENTO VALUE
										INSERT ARTran (acct,acctdist,batnbr,cmmnpct,cnvfact,contractid,costtype,cpnyid,crtd_datetime,crtd_prog,crtd_user,
														curyextcost,curyid,curymultdiv,curyrate,curytaxamt00,curytaxamt01,curytaxamt02,curytaxamt03,curytranamt,
														curytxblamt00,curytxblamt01,curytxblamt02,curytxblamt03,curyunitprice,custid,drcr,excpt,extcost,extrefnbr,
														fiscyr,flatratelinenbr,installnbr,invtid,jobrate,jrnltype,lineid,linenbr,lineref,lupd_datetime,lupd_prog,lupd_user,
														masterdocnbr,noteid,ordnbr,pc_flag,pc_id,pc_status,perent,perpost,projectid,qty,refnbr,rlsed,
														s4future01,s4future02,s4future03,s4future04,s4future05,s4future06,s4future07,s4future08,s4future09,s4future10,s4future11,s4future12,
														servicecallid,servicecalllinenbr,servicedate,shippercpnyid,shipperid,shipperlineref,siteid,slsperid,specificcostid,sub,
														taskid,taxamt00,taxamt01,taxamt02,taxamt03,taxcalced,taxcat,taxid00,taxid01,taxid02,taxid03,taxiddflt,tranamt,
														tranclass,trandate,trandesc,trantype,txblamt00,txblamt01,txblamt02,txblamt03,unitdesc,unitprice,
														user1,user2,user3,user4,user5,user6,user7,user8,whseloc)  
										VALUES( '216101', 0, @BatNbr, 0, 0, '', '', @CpnyId, GETDATE(), '08010', @UserId, 
												0, @CuryId, 'M', 1, 0, 0, 0, 0, (@DocBal), 
												0, 0, 0, 0, @CuryUnitPrice, @CustId, @DRCR, 0, 0, @ExtRefNbr, 
												@FiscYr, 0, 0, @InvtId, 0, 'AR', @LineId, @LineNbr, '', GETDATE(), '08010', @UserId, 
												--'', 0, '', '', '', '', @PerEnt, @PerPost, '', @Qty, (REPLACE ( @NumContrato , '-' , '' )+right(convert(varchar(3),@RefNbr+100),2) + SUBSTRING(@DocType,0,2)), 0, 
												'', 0, '', '', '', '', @PerEnt, @PerPost, '', @Qty, @RefNbr, 0, 
												'', '', 0, 0, 0, 0, '01/01/1900 ', '01/01/1900 ', 0, 0, '', '', 
												SUBSTRING ( @ServiceCallId ,0 , 10 ), 0, @DocDate, '', '', '', '', @SlsPerId, '', @SlsSub, 
												'', 0, 0, 0, 0, 'N', '', '', '', '', '', 'TASA0', (@DocBal), 
												'', @DocDate,rtrim(@CustId)+ '-C:'+@NumContrato+@Anexo+'Renta', @DocType, 0, 0, 0, 0, '', @UnitPrice, 
												'', '', 0, 0, '', '', '01/01/1900 ', '01/01/1900 ', '')
										-- LINEID, LINENBR
										SET @LineId = 1 + @LineId
										SET @LineNbr  = 1 + @LineNbr

											-- INSERTA UNA PARTIDA PARA IVA ARRENDAMIENTO VALUE
										INSERT ARTran (acct,acctdist,batnbr,cmmnpct,cnvfact,contractid,costtype,cpnyid,crtd_datetime,crtd_prog,crtd_user,
														curyextcost,curyid,curymultdiv,curyrate,curytaxamt00,curytaxamt01,curytaxamt02,curytaxamt03,curytranamt,
														curytxblamt00,curytxblamt01,curytxblamt02,curytxblamt03,curyunitprice,custid,drcr,excpt,extcost,extrefnbr,
														fiscyr,flatratelinenbr,installnbr,invtid,jobrate,jrnltype,lineid,linenbr,lineref,lupd_datetime,lupd_prog,lupd_user,
														masterdocnbr,noteid,ordnbr,pc_flag,pc_id,pc_status,perent,perpost,projectid,qty,refnbr,rlsed,
														s4future01,s4future02,s4future03,s4future04,s4future05,s4future06,s4future07,s4future08,s4future09,s4future10,s4future11,s4future12,
														servicecallid,servicecalllinenbr,servicedate,shippercpnyid,shipperid,shipperlineref,siteid,slsperid,specificcostid,sub,
														taskid,taxamt00,taxamt01,taxamt02,taxamt03,taxcalced,taxcat,taxid00,taxid01,taxid02,taxid03,taxiddflt,tranamt,
														tranclass,trandate,trandesc,trantype,txblamt00,txblamt01,txblamt02,txblamt03,unitdesc,unitprice,
														user1,user2,user3,user4,user5,user6,user7,user8,whseloc)  
										VALUES( '216101', 0, @BatNbr, 0, 0, '', '', @CpnyId, GETDATE(), '08010', @UserId, 
												0, @CuryId, 'M', 1, 0, 0, 0, 0, @IvaCXC, 
												0, 0, 0, 0, @CuryUnitPrice, @CustId, @DRCR, 0, 0, @ExtRefNbr, 
												@FiscYr, 0, 0, @InvtId, 0, 'AR', @LineId, @LineNbr, '', GETDATE(), '08010', @UserId, 
												--'', 0, '', '', '', '', @PerEnt, @PerPost, '', @Qty, (REPLACE ( @NumContrato , '-' , '' )+right(convert(varchar(3),@RefNbr+100),2) + SUBSTRING(@DocType,0,2)), 0, 
												'', 0, '', '', '', '', @PerEnt, @PerPost, '', @Qty, @RefNbr, 0, 
												'', '', 0, 0, 0, 0, '01/01/1900 ', '01/01/1900 ', 0, 0, '', '', 
												SUBSTRING ( @ServiceCallId ,0 , 10 ), 0, @DocDate, '', '', '', '', @SlsPerId, '', @SlsSub, 
												'', 0, 0, 0, 0, 'N', '', '', '', '', '', 'TASA0', @IvaCXC, 
												'', @DocDate,rtrim(@CustId)+ '-C:'+@NumContrato+@Anexo+'Iva Renta', @DocType, 0, 0, 0, 0, '', @UnitPrice, 
												'', '', 0, 0, '', '', '01/01/1900 ', '01/01/1900 ', '')
										-- LINEID, LINENBR
										SET @LineId = 1 + @LineId
										SET @LineNbr  = 1 + @LineNbr
									END
									ELSE
									BEGIN 
											IF (@CuryTranAmt) <> '0'
											BEGIN 
												-- INSERT CAPITAL VALUE
												INSERT ARTran (acct,acctdist,batnbr,cmmnpct,cnvfact,contractid,costtype,cpnyid,crtd_datetime,crtd_prog,crtd_user,
																curyextcost,curyid,curymultdiv,curyrate,curytaxamt00,curytaxamt01,curytaxamt02,curytaxamt03,curytranamt,
																curytxblamt00,curytxblamt01,curytxblamt02,curytxblamt03,curyunitprice,custid,drcr,excpt,extcost,extrefnbr,
																fiscyr,flatratelinenbr,installnbr,invtid,jobrate,jrnltype,lineid,linenbr,lineref,lupd_datetime,lupd_prog,lupd_user,
																masterdocnbr,noteid,ordnbr,pc_flag,pc_id,pc_status,perent,perpost,projectid,qty,refnbr,rlsed,
																s4future01,s4future02,s4future03,s4future04,s4future05,s4future06,s4future07,s4future08,s4future09,s4future10,s4future11,s4future12,
																servicecallid,servicecalllinenbr,servicedate,shippercpnyid,shipperid,shipperlineref,siteid,slsperid,specificcostid,sub,
																taskid,taxamt00,taxamt01,taxamt02,taxamt03,taxcalced,taxcat,taxid00,taxid01,taxid02,taxid03,taxiddflt,tranamt,
																tranclass,trandate,trandesc,trantype,txblamt00,txblamt01,txblamt02,txblamt03,unitdesc,unitprice,
																user1,user2,user3,user4,user5,user6,user7,user8,whseloc)  
												VALUES( '214003', 0, @BatNbr, 0, 0, '', '', @CpnyId, GETDATE(), '08010', @UserId, 
														0, @CuryId, 'M', 1, 0, 0, 0, 0, @CuryTranAmt, 
														0, 0, 0, 0, @CuryUnitPrice, @CustId, @DRCR, 0, 0, @ExtRefNbr, 
														@FiscYr, 0, 0, @InvtId, 0, 'AR', @LineId, @LineNbr, '', GETDATE(), '08010', @UserId, 
														--'', 0, '', '', '', '', @PerEnt, @PerPost, '', @Qty, (REPLACE ( @NumContrato , '-' , '' )+right(convert(varchar(3),@RefNbr+100),2) + SUBSTRING(@DocType,0,2)), 0, 
														'', 0, '', '', '', '', @PerEnt, @PerPost, '', @Qty, @RefNbr, 0, 
														'', '', 0, 0, 0, 0, '01/01/1900 ', '01/01/1900 ', 0, 0, '', '', 
														SUBSTRING ( @ServiceCallId ,0 , 10 ), 0, @DocDate, '', '', '', '', @SlsPerId, '', @SlsSub, 
														'', 0, 0, 0, 0, 'N', '', '', '', '', '', 'TASA0', @TranAmt, 
														'', @DocDate,rtrim(@CustId)+ '-C:'+@NumContrato+@Anexo+'Cap_Aut y Se', @DocType, 0, 0, 0, 0, '', @UnitPrice, 
														'', '', 0, 0, '', '', '01/01/1900 ', '01/01/1900 ', '')
												-- LINEID, LINENBR
												SET @LineId = 1 + @LineId
												SET @LineNbr  = 1 + @LineNbr
											END 	
											IF (@CuryTranAmtI) <> '0'
											BEGIN 
												-- INSERT INTERES VALUE
												INSERT ARTran (acct,acctdist,batnbr,cmmnpct,cnvfact,contractid,costtype,cpnyid,crtd_datetime,crtd_prog,crtd_user,
																curyextcost,curyid,curymultdiv,curyrate,curytaxamt00,curytaxamt01,curytaxamt02,curytaxamt03,curytranamt,
																curytxblamt00,curytxblamt01,curytxblamt02,curytxblamt03,curyunitprice,custid,drcr,excpt,extcost,extrefnbr,
																fiscyr,flatratelinenbr,installnbr,invtid,jobrate,jrnltype,lineid,linenbr,lineref,lupd_datetime,lupd_prog,lupd_user,
																masterdocnbr,noteid,ordnbr,pc_flag,pc_id,pc_status,perent,perpost,projectid,qty,refnbr,rlsed,
																s4future01,s4future02,s4future03,s4future04,s4future05,s4future06,s4future07,s4future08,s4future09,s4future10,s4future11,s4future12,
																servicecallid,servicecalllinenbr,servicedate,shippercpnyid,shipperid,shipperlineref,siteid,slsperid,specificcostid,sub,
																taskid,taxamt00,taxamt01,taxamt02,taxamt03,taxcalced,taxcat,taxid00,taxid01,taxid02,taxid03,taxiddflt,tranamt,
																tranclass,trandate,trandesc,trantype,txblamt00,txblamt01,txblamt02,txblamt03,unitdesc,unitprice,
																user1,user2,user3,user4,user5,user6,user7,user8,whseloc)  
												VALUES( '216001', 0, @BatNbr, 0, 0, '', '', @CpnyId, GETDATE(), '08010', @UserId, 
														0, @CuryId, 'M', 1, 0, 0, 0, 0, @CuryTranAmtI, 
														0, 0, 0, 0, @CuryUnitPrice, @CustId, @DRCR, 0, 0, @ExtRefNbr, 
														@FiscYr, 0, 0, @InvtId, 0, 'AR', @LineId, @LineNbr, '', GETDATE(), '08010', @UserId, 
														--'', 0, '', '', '', '', @PerEnt, @PerPost, '', @Qty, (REPLACE ( @NumContrato , '-' , '' )+right(convert(varchar(3),@RefNbr+100),2) + SUBSTRING(@DocType,0,2)), 0, 
														'', 0, '', '', '', '', @PerEnt, @PerPost, '', @Qty, @RefNbr, 0, 
														'', '', 0, 0, 0, 0, '01/01/1900 ', '01/01/1900 ', 0, 0, '', '', 
														SUBSTRING ( @ServiceCallId ,0 , 10 ), 0, @DocDate, '', '', '', '', @SlsPerId, '', '0000000', 
														'', 0, 0, 0, 0, 'N', '', '', '', '', '', 'TASA0', @TranAmtI, 
														'', @DocDate,rtrim(@CustId)+ '-C:'+@NumContrato+@Anexo+'Int_Aut y Se', @DocType, 0, 0, 0, 0, '', @UnitPrice, 
														'', '', 0, 0, '', '', '01/01/1900 ', '01/01/1900 ', '')
												SET @LineId = 1 + @LineId
												SET @LineNbr  = 1 + @LineNbr
											END 
											IF (@CuryTranAmtIV) <> '0' 
											BEGIN 
												-- INSERT IVA VALUE
												INSERT ARTran (acct,acctdist,batnbr,cmmnpct,cnvfact,contractid,costtype,cpnyid,crtd_datetime,crtd_prog,crtd_user,
																curyextcost,curyid,curymultdiv,curyrate,curytaxamt00,curytaxamt01,curytaxamt02,curytaxamt03,curytranamt,
																curytxblamt00,curytxblamt01,curytxblamt02,curytxblamt03,curyunitprice,custid,drcr,excpt,extcost,extrefnbr,
																fiscyr,flatratelinenbr,installnbr,invtid,jobrate,jrnltype,lineid,linenbr,lineref,lupd_datetime,lupd_prog,lupd_user,
																masterdocnbr,noteid,ordnbr,pc_flag,pc_id,pc_status,perent,perpost,projectid,qty,refnbr,rlsed,
																s4future01,s4future02,s4future03,s4future04,s4future05,s4future06,s4future07,s4future08,s4future09,s4future10,s4future11,s4future12,
																servicecallid,servicecalllinenbr,servicedate,shippercpnyid,shipperid,shipperlineref,siteid,slsperid,specificcostid,sub,
																taskid,taxamt00,taxamt01,taxamt02,taxamt03,taxcalced,taxcat,taxid00,taxid01,taxid02,taxid03,taxiddflt,tranamt,
																tranclass,trandate,trandesc,trantype,txblamt00,txblamt01,txblamt02,txblamt03,unitdesc,unitprice,
																user1,user2,user3,user4,user5,user6,user7,user8,whseloc)  
												VALUES( '216001', 0, @BatNbr, 0, 0, '', '', @CpnyId, GETDATE(), '08010', @UserId, 
														0, @CuryId, 'M', 1, 0, 0, 0, 0, @CuryTranAmtIV, 
														0, 0, 0, 0, @CuryUnitPrice, @CustId, @DRCR, 0, 0, @ExtRefNbr, 
														@FiscYr, 0, 0, @InvtId, 0, 'AR', @LineId, @LineNbr, '', GETDATE(), '08010', @UserId, 
														--'', 0, '', '', '', '', @PerEnt, @PerPost, '', @Qty, (REPLACE ( @NumContrato , '-' , '' )+right(convert(varchar(3),@RefNbr+100),2) + SUBSTRING(@DocType,0,2)), 0, 
														'', 0, '', '', '', '', @PerEnt, @PerPost, '', @Qty, @RefNbr, 0, 
														'', '', 0, 0, 0, 0, '01/01/1900 ', '01/01/1900 ', 0, 0, '', '', 
														SUBSTRING ( @ServiceCallId ,0 , 10 ), 0, @DocDate, '', '', '', '', @SlsPerId, '', @SlsSub, 
														'', 0, 0, 0, 0, 'N', '', '', '', '', '', 'TASA0', @TranAmtIV, 
														'', @DocDate,rtrim(@CustId)+ '-C:'+@NumContrato+@Anexo+'Iva_Aut_Seg', @DocType, 0, 0, 0, 0, '', @UnitPrice, 
														'', '', 0, 0, '', '', '01/01/1900 ', '01/01/1900 ', '')
												-- LINEID, LINENBR
												SET @LineId = 1 + @LineId
												SET @LineNbr  = 1 + @LineNbr
											END
											IF (@CuryTranAmtL) <> '0'
											BEGIN
												-- INSERT LOCALIZADOR VALUE
												INSERT ARTran (acct,acctdist,batnbr,cmmnpct,cnvfact,contractid,costtype,cpnyid,crtd_datetime,crtd_prog,crtd_user,
																curyextcost,curyid,curymultdiv,curyrate,curytaxamt00,curytaxamt01,curytaxamt02,curytaxamt03,curytranamt,
																curytxblamt00,curytxblamt01,curytxblamt02,curytxblamt03,curyunitprice,custid,drcr,excpt,extcost,extrefnbr,
																fiscyr,flatratelinenbr,installnbr,invtid,jobrate,jrnltype,lineid,linenbr,lineref,lupd_datetime,lupd_prog,lupd_user,
																masterdocnbr,noteid,ordnbr,pc_flag,pc_id,pc_status,perent,perpost,projectid,qty,refnbr,rlsed,
																s4future01,s4future02,s4future03,s4future04,s4future05,s4future06,s4future07,s4future08,s4future09,s4future10,s4future11,s4future12,
																servicecallid,servicecalllinenbr,servicedate,shippercpnyid,shipperid,shipperlineref,siteid,slsperid,specificcostid,sub,
																taskid,taxamt00,taxamt01,taxamt02,taxamt03,taxcalced,taxcat,taxid00,taxid01,taxid02,taxid03,taxiddflt,tranamt,
																tranclass,trandate,trandesc,trantype,txblamt00,txblamt01,txblamt02,txblamt03,unitdesc,unitprice,
																user1,user2,user3,user4,user5,user6,user7,user8,whseloc)  
												VALUES( '113008', 0, @BatNbr, 0, 0, '', '', @CpnyId, GETDATE(), '08010', @UserId, 
														0, @CuryId, 'M', 1, 0, 0, 0, 0, @CuryTranAmtL, 
														0, 0, 0, 0, @CuryUnitPrice, @CustId, @DRCR, 0, 0, @ExtRefNbr, 
														@FiscYr, 0, 0, @InvtId, 0, 'AR', @LineId, @LineNbr, '', GETDATE(), '08010', @UserId, 
														--'', 0, '', '', '', '', @PerEnt, @PerPost, '', @Qty, (REPLACE ( @NumContrato , '-' , '' )+right(convert(varchar(3),@RefNbr+100),2) + SUBSTRING(@DocType,0,2)), 0, 
														'', 0, '', '', '', '', @PerEnt, @PerPost, '', @Qty, @RefNbr, 0, 
														'', '', 0, 0, 0, 0, '01/01/1900 ', '01/01/1900 ', 0, 0, '', '', 
														SUBSTRING ( @ServiceCallId ,0 , 10 ), 0, @DocDate, '', '', '', '', @SlsPerId, '', @SlsSub, 
														'', 0, 0, 0, 0, 'N', '', '', '', '', '', 'TASA0', @TranAmtL, 
														'', @DocDate,rtrim(@CustId)+ '-C:'+@NumContrato+@Anexo+'Cap_Localiz', @DocType, 0, 0, 0, 0, '', @UnitPrice, 
														'', '', 0, 0, '', '', '01/01/1900 ', '01/01/1900 ', '')
												-- LINEID, LINENBR
												SET @LineId = 1 + @LineId
												SET @LineNbr  = 1 + @LineNbr
											END
										END

										FETCH NEXT FROM ARTran_Cursor
										INTO  @SlsAcct, 
									@CuryTranAmt, @CuryUnitPrice,
									@CuryTranAmtI, @CuryUnitPriceI,
									@CuryTranAmtIV, @CuryUnitPriceIV,
									@ExtRefNbr, @InvtId, @Qty, @SlsSub, 
									@TranAmt, @UnitPrice,
									@TranAmtI, @UnitPriceI,
									@TranAmtIV, @UnitPriceIV,
									@TranAmtL, @UnitPriceL,
									@TranAmtL, @UnitPriceL

										END
									CLOSE ARTran_Cursor
									DEALLOCATE ARTran_Cursor
									SELECT @DocBal2 = ROUND(SUM(ARTran.TranAmt), 2), 
											@CuryDocBal2 = ROUND(SUM(ARTran.CuryTranAmt), 2)
									FROM ARDoc INNER JOIN ARTran ON
											ARTran.BatNbr = ARDoc.BatNbr AND
											ARTran.RefNbr = ARDoc.RefNbr
									WHERE ARDoc.BatNbr = @BatNbr AND ARDoc.RefNbr = @RefNbr
									GROUP BY ARDoc.RefNbr, ARDoc.DocBal, ARDoc.CuryDocBal, ARDoc.OrigDocAmt, ARDoc.CuryOrigDocAmt

									UPDATE ARDoc SET DocBal = @DocBal2,
													CuryDocBal = @CuryDocBal2,
													OrigDocAmt = @DocBal2,
													CuryOrigDocAmt = @CuryDocBal2
									WHERE ARDoc.BatNbr = @BatNbr AND ARDoc.RefNbr = @RefNbr
								------------------- END CURSOR FOR ARTRAN -----------------------------
								
								FETCH NEXT FROM ARDoc_Cursor
								INTO @RefNbr, @ARAcct, @ARSub, @DocBal, @CuryTxblTot00, @CustId, @ServiceCallId, @DueDate, @SlsPerId, @TaxId00, @TaxTot00, @TxblTot00, @TermsId,@NumContrato, @Plazo,@Anexo,@TipoCredito,@IvaCXC,@FechaPago
							END
							CLOSE ARDoc_Cursor
							DEALLOCATE ARDoc_Cursor
				------------------- END CURSOR FOR ARDOC -----------------------------
				SELECT @DocBal3 = ROUND(SUM(ARDoc.OrigDocAmt), 2), 
						@CuryDocBal3 = ROUND(SUM(ARDoc.CuryOrigDocAmt), 2)
				FROM ARDoc 
				WHERE ARDoc.BatNbr = @BatNbr

				UPDATE Batch SET CrTot = @DocBal3, CtrlTot = @DocBal3, CuryCrTot = @DocBal3, CuryCtrlTot = @DocBal3, Status = 'B'
				WHERE Batch.BatNbr = @BatNbr AND Module = 'AR'
				
				FETCH NEXT FROM Batch_Cursor
				INTO @DocDate, @CpnyId, @SucursalId, @LedgerId, @CuryId, @ControlOrdServ, @CtrlTot
		END
		CLOSE Batch_Cursor
		DEALLOCATE Batch_Cursor
		UPDATE ARSETUP SET Lastrefnbr = (select TOP 1 RefNbr+1 from AUCorteServ WHERE SERVICECALLID = @IDOportunity ORDER BY REFNBR  )
		-- ********************************************************************
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
		BEGIN		
			ROLLBACK TRANSACTION
			 SELECT
			ERROR_NUMBER() AS ErrorNumber
			,ERROR_SEVERITY() AS ErrorSeverity
			,ERROR_STATE() AS ErrorState
			,ERROR_PROCEDURE() AS ErrorProcedure
			,ERROR_LINE() AS ErrorLine
			,ERROR_MESSAGE() AS ErrorMessage;
		END
	END CATCH
	IF @@TRANCOUNT > 0
	BEGIN 
		COMMIT TRANSACTION
	--DELETE WrkRelease Where UserAddress =  'SERVERSLRDP-Tcp#1' AND Module =  'AP' 
	--DELETE WrkReleaseBad Where UserAddress =  'SERVERSLRDP-Tcp#1'  AND Module =  'AP'
	--EXEC PStatus_Cleanup 'SERVERSLRDP-Tcp#1', 4
	--EXEC pp_CleanWrkRelease 'SERVERSLRDP-Tcp#1', 'AP' 
	--EXEC pp_CleanWrkRelease_PO 'SERVERSLRDP-Tcp#1'
	--EXEC pp_WrkReleaseRec @Batnbr, 'AP', 'SERVERSLRDP-Tcp#1', 1 
	--EXEC pp_WrkRelease_PORec @Batnbr, 'AP', 'SERVERSLRDP-Tcp#1' 
	--EXEC pp_03400 'SERVERSLRDP-Tcp#1' , 'SYSADMIN' 
	----Remplazar HELIOPCConsole por 'SERVERSLRDP-Tcp#1'
	----'SERVERSLRDP-Tcp#1'
	END 
		




