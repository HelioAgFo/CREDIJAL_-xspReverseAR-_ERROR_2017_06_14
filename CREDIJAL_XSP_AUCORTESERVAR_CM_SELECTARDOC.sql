SELECT 
									(Select top 1 refnbr from AUCorteServ where ServiceCallId = @IDOportunity order by RefNbr) Refnbr,
									AUCtasServ.ARAcct,
									AUCtasServ.ARSub,
									Round(LTRIM(Convert(decimal(10, 2),SUM(AUCorteServ.Pago))),2),
									Round(LTRIM(Convert(decimal(10, 2),SUM(AUCorteServ.Pago))),2),
									AUCorteServ.CustID, AUCorteServ.ServiceCallID, 
									DATEADD(DAY, Terms.DueIntrv, 
									CONVERT(VARCHAR(10), AUCorteServ.DocDate2, 101)),
									'' Asesor, Customer.TaxID00, 
									Round(LTRIM(Convert(decimal(10, 2),SUM(AUCorteServ.Pago))),2),
									Round(LTRIM(Convert(decimal(10, 2),SUM(AUCorteServ.Pago))),2),
									ISNULL(terms.TermsId, 'A7'),
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
									LEFT OUTER JOIN Terms ON
									AUCorteServ.PLAZO = Terms.NbrInstall
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
									AUCorteServ.CustID, AUCorteServ.ServiceCallID, DATEADD(DAY, Terms.DueIntrv, AUCorteServ.DocDate2),
									Customer.TaxID00, SalesTax.TaxRate, Terms.DueIntrv,
									CONVERT(VARCHAR(10), AUCorteServ.DocDate2, 101),
									AUCorteServ.CpnyID, AUCorteServ.SucursalID, 
									terms.TermsId,
									aucorteserv.NumeroContrato,
									AUCorteServ.plazo,
									AUCorteServ.TipoCreditoCompleto,
									AUCtasServ.ARAcct, 
									AUCtasServ.ARSub,
									AUCorteServ.TipoCredito,
									AUCORTESERV.IvaCXC
							ORDER BY CONVERT(VARCHAR(10), AUCorteServ.DocDate2, 101), AUCorteServ.CpnyId, AUCorteServ.SucursalId