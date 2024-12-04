B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=9.85
@EndOfDesignText@
#Region Shared Files
#CustomBuildAction: folders ready, %WINDIR%\System32\Robocopy.exe,"..\..\Shared Files" "..\Files"
'Ctrl + click to sync files: ide://run?file=%WINDIR%\System32\Robocopy.exe&args=..\..\Shared+Files&args=..\Files&FilesSync=True
#End Region

'Ctrl + click to export as zip: ide://run?File=%B4X%\Zipper.jar&Args=Project.zip

Sub Class_Globals
	Private Root As B4XView
	Private xui As XUI
	Private KeyValue As KeyValueStore
	Private RevCat As RevenueCat
	#If B4I
	Private inAppPurchase As Store
	#End If
	Private m_HasPremium As Boolean = False
End Sub

Public Sub Initialize
	
End Sub

'This event will be called once, before the page becomes visible.
Private Sub B4XPage_Created (Root1 As B4XView)
	Root = Root1
	Root.LoadLayout("frm_main")
	
	B4XPages.SetTitle(Me,"RevenueCat Example")
	
	#If B4I
	inAppPurchase.Initialize("inAppPurchase")
	#End If
	
	KeyValue.Initialize(xui.DefaultFolder,"AppSettings") 'For saving relevant subscription data
	Dim RevCatUserId As String = KeyValue.GetDefault("RevCatUserId",GUID) 'If no user guid is saved, then generate a new
	KeyValue.Put("RevCatUserId",RevCatUserId)
	RevCat.Initialize("RevenueCatAPIKey",RevCatUserId,Array As String("all_access_1_year","all_access_1_month"))
	CheckPurchases

End Sub

Private Sub CheckPurchases As ResumableSub
	If KeyValue.GetDefault("RevenueCat_SubscriptionExpiresDate","") = "" Or KeyValue.Get("RevenueCat_SubscriptionExpiresDate").As(Long) < DateTime.Now Then 'Get the saved subscription infos
		
		Wait For (RevCat.GetCustomer) complete (Subscription As RevenueCat_Subscription) 'Gets customer infos
		
		If Subscription.Error.Success And Subscription.ExpiresDate > DateTime.Now Then
			KeyValue.Put("RevenueCat_SubscriptionExpiresDate",Subscription.ExpiresDate) 'Save the new expire date
		End If
		
	End If

	Log(DateUtils.TicksToString(KeyValue.Get("RevenueCat_SubscriptionExpiresDate").As(Long)))
	m_HasPremium = KeyValue.Get("RevenueCat_SubscriptionExpiresDate").As(Long) > DateTime.Now 'If the expire date is greater than now then he have an active subsription
	Log("Has Premium? "  & m_HasPremium)
	Return True
End Sub

Private Sub xlbl_Purchase_Click
	
	Dim ProductIdentifier As String = "all_access_1_year"
	
	inAppPurchase.RequestPayment(ProductIdentifier)
	Wait For inAppPurchase_PurchaseCompleted (Success As Boolean, Product As Purchase)
	
	RevCat.GetCustomer
	Wait For (RevCat.CreatePurchase(Product.ProductIdentifier,Product)) complete (Subscription As RevenueCat_Subscription)

	If Subscription.Error.Success Then
		KeyValue.Put("RevenueCat_SubscriptionExpiresDate",Subscription.ExpiresDate)
	End If
	
	If Success Then
		
		Dim sf As Object = xui.MsgboxAsync("You are now ready to go","Your purchase was successful.")
		Wait For (sf) Msgbox_Result (Result As Int)

		'UnlockPremiumFunctions
		'Sleep(0)
		'B4XPages.ClosePage(Me)
	Else
		xui.MsgboxAsync("Purchase Failed","Purchase was cancelled.")
	End If
	
End Sub

Private Sub RestorePurchases
	inAppPurchase.RestoreTransactions
	Wait For inAppPurchase_TransactionsRestored (Success As Boolean)
	If Success Then
		Wait For (CheckPurchases) complete (Success As Boolean)
	
		If m_HasPremium = False And KeyValue.Get("RevenueCat_SubscriptionExpiresDate") <> "" Then
			KeyValue.Put("RevenueCat_SubscriptionExpiresDate","") 'Reset
			xui.MsgboxAsync("The Pro version has been canceled or not renewed, you are now using the basic version.","Pro Version expired")
		Else if m_HasPremium Then
			'UnlockPremiumFunctions
			xui.MsgboxAsync("Recovery successful","Your purchases have been successfully restored")
		Else
			xui.MsgboxAsync("Purchase Failed","Purchase was cancelled.")
		End If
	Else
		xui.MsgboxAsync("Restore failed","No purchases found to restore.")
	End If
End Sub

'Generates a new GUID
Public Sub GUID As String
	Dim sb As StringBuilder
	sb.Initialize
	For Each stp As Int In Array(8, 4, 4, 4, 12)
		If sb.Length > 0 Then sb.Append("-")
		For n = 1 To stp
			Dim c As Int = Rnd(0, 16)
			If c < 10 Then c = c + 48 Else c = c + 55
			sb.Append(Chr(c))
		Next
	Next
	Return sb.ToString
End Sub