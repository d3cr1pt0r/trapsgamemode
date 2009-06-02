require("datastream")
if SERVER then
	function get_datastream_chat_data( pl, handler, id, encoded, decoded )
		local receivedstring = decoded[1]
		local stringsender = decoded[2]
		
		umsg.Start("SendData")
			umsg.String(receivedstring)
			umsg.String(stringsender)
		umsg.End()
	end
	function get_datastream_player_status( pl, handler, id, encoded, decoded )
		local chat_player = decoded[1]
		local chat_ply_status = decoded[2]
		if (chat_ply_status == 1) then
			for k,v in pairs(player.GetAll()) do
				v:ChatPrint(decoded[1].." has joined the chat.")
			end
			umsg.Start("PlayerJoined")
				umsg.String(decoded[1])
			umsg.End()
		end
		if (chat_ply_status == 0) then
			for k,v in pairs(player.GetAll()) do
				v:ChatPrint(decoded[1].." has left the chat.")
			end
			umsg.Start("PlayerLeft")
				umsg.String(decoded[1])
			umsg.End()
		end
	end
	datastream.Hook( "PlayerChatData", get_datastream_chat_data )
	datastream.Hook( "PlayerChatStatus", get_datastream_player_status )
end

if CLIENT then
	ChatContent = {}
	OnlinePlayers = {}

	function chatdata( um )
		CHAT_string = um:ReadString()
		CHAT_sender = um:ReadString()
		table.insert(ChatContent, {CHAT_sender, CHAT_string})
		RefreshChat(DermaListView)
	end
	function Player_Joined( um )
		table.insert(OnlinePlayers, um:ReadString())
		AddPlayerToList()
	end
	function Player_Left( um )
		local ply_lol = um:ReadString()
		for k,v in pairs(OnlinePlayers) do
			if (v == ply_lol) then
				table.remove(OnlinePlayers, k)
			end
		end
		if (table.HasValue(OnlinePlayers, ply_lol)) then
			Delete_Shit(ply_lol)
		end
		AddPlayerToList()
	end
	// THE UBER WIN PAART!!! :D
	function Delete_Shit(ply_lol)
		for k,v in pairs(OnlinePlayers) do
			if (v == ply_lol) then
				table.remove(OnlinePlayers, k)
			end
		end
		if (table.HasValue(OnlinePlayers, ply_lol)) then
			Delete_Shit(ply_lol)
		end
	end
	function customchat()
	
		datastream.StreamToServer( "PlayerChatStatus", { LocalPlayer():Name(), 1 } )
	
		local DermaFrame = vgui.Create( "DFrame" )
		DermaFrame:SetPos( 50,50 )
		DermaFrame:SetSize( 900, 500 )
		DermaFrame:SetSizable( true )
		DermaFrame:SetTitle( "Chat Program" )
		DermaFrame:SetVisible( true )
		DermaFrame:SetDraggable( true )
		DermaFrame:ShowCloseButton( false )
		DermaFrame:MakePopup()
		
		
		TestingComboBox = vgui.Create( "DComboBox", DermaFrame )
		TestingComboBox:SetPos( 720,100 )
		TestingComboBox:EnableVerticalScrollbar( false )
		TestingComboBox:SetSize( 150, 300 )
		
		TestingComboBox:SetMultiple( true )
		
		local DermaButton = vgui.Create( "DButton" )
		DermaButton:SetParent( DermaFrame )
		DermaButton:SetText( "Clear Chat" )
		DermaButton:SetPos( 720, 50 )
		DermaButton:SetSize( 60, 20 )
		DermaButton.DoClick = function ()
			DermaListView:Clear()
			table.Empty(ChatContent)
		end
		
		local DermaButton = vgui.Create( "DButton" )
		DermaButton:SetParent( DermaFrame )
		DermaButton:SetText( "Close Chat" )
		DermaButton:SetPos( 720, 80 )
		DermaButton:SetSize( 60, 20 )
		DermaButton.DoClick = function ()
			DermaFrame:SetVisible( false )
			datastream.StreamToServer( "PlayerChatStatus", { LocalPlayer():Name(), 0 } )
		end

		local DermaText = vgui.Create( "DTextEntry", DermaFrame )
		DermaText:SetPos( 25,475 )
		DermaText:SetTall( 20 )
		DermaText:SetWide( 675 )
		DermaText:SetEnterAllowed( true )
		DermaText:RequestFocus()
		DermaText.OnEnter = function()
			if (DermaText:GetValue() != "") then
				datastream.StreamToServer( "PlayerChatData", { DermaText:GetValue(), LocalPlayer():Name() } )
			end
			DermaText:SetText( "" )
			DermaText:RequestFocus()
		end

		 
		DermaListView = vgui.Create("DListView")
		DermaListView:SetParent(DermaFrame)
		DermaListView:SetPos(25, 50)
		DermaListView:SetSize(675, 400)
		DermaListView:SetSortable( false )
		DermaListView:SetMultiSelect(false)
		local Sender = DermaListView:AddColumn("Sender")
		local Message = DermaListView:AddColumn("Message")
		Message:SetWide(300)
		
		for k,v in pairs(ChatContent) do
			DermaListView:AddLine(v[1],v[2])
		end
		
		function RefreshChat(DermaListView)
			DermaListView:AddLine(CHAT_sender,CHAT_string)
		end
	end
	
	function AddPlayerToList()
		TestingComboBox:Clear()
		for k,v in pairs(OnlinePlayers) do
			TestingComboBox:AddItem(v)
		end
	end
	
	usermessage.Hook("PlayerJoined",Player_Joined)
	usermessage.Hook("PlayerLeft",Player_Left)
	usermessage.Hook("SendData",chatdata)
	concommand.Add("custom_chat", customchat)
end
