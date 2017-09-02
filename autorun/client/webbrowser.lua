local Tag='custombrowser'


-- javascript hacks

local fixselect = [[
(function() {
if (document.getElementsByTagName("select").length>0) {

    if (!window.jQuery) {
        var script = document.createElement("SCRIPT");
        script.src = 'https://ajax.googleapis.com/ajax/libs/jquery/1.7.1/jquery.min.js';
        script.type = 'text/javascript';
        document.getElementsByTagName("head")[0].appendChild(script);
    }
    var checkReady = function(callback) {
        if (window.jQuery) {
            callback(jQuery);
        } else {
            window.setTimeout(function() {
                checkReady(callback);
            }, 100);
        }
    };

    checkReady(function($) {

        (function($) {
            console.log("loaded jquery");
            var script = document.createElement("SCRIPT");
            script.src = 'https://cdnjs.cloudflare.com/ajax/libs/select2/4.0.0-rc.2/js/select2.min.js';
            script.type = 'text/javascript';
            document.getElementsByTagName("head")[0].appendChild(script);


            var head = document.getElementsByTagName('head')[0];
            var link = document.createElement('link');
            link.rel = 'stylesheet';
            link.type = 'text/css';
            link.href = 'https://cdnjs.cloudflare.com/ajax/libs/select2/4.0.0-rc.2/css/select2.min.css';
            link.media = 'all';
            head.appendChild(link);

            var checkReady = function(callback) {
                if ($.fn.select2 == null) {
                    window.setTimeout(function() {
                        checkReady(callback);
                    }, 100);
                } else {
                    callback();
                }
            };

            checkReady(function() {
                console.log("loaded select2");
                $('select').select2();
                console.log("injected select replacement");
            });
        })($);



    });

};

})();

]]

local PANEL={}

function PANEL:Init()
	self.firstload=true
	self:SetVisible(false)
	self:SetSize(ScrW()*0.9,ScrH()*0.8)
	self:Center()
	self:SetTitle( "Web Browser" )
	self:SetDeleteOnClose( false )
	self:ShowCloseButton( true )
	self:SetDraggable( true )
	self:SetSizable( true )
	if self.btnMinim then
		self.btnMinim:SetDisabled(false)
		self.btnMinim.DoClick=function() self:SetVisible(false) end
	end
	if self.btnMaxim then
		self.btnMaxim:SetDisabled(false)
		self.btnMaxim.DoClick=function() self:SetSize(ScrW(),ScrH()) self:Center() end
	end
	local top = vgui.Create( "EditablePanel", self )
		self.top=top
		top:Dock(TOP)
		top:SetTall(24)
	local PreviousIcon = "icon16/arrow_left.png"
	local NextIcon	   = "icon16/arrow_right.png"
	local btn = vgui.Create("DButton",self.top)
		btn:SetText("")
		btn:SetSize(24,24)
		btn:SetIcon(PreviousIcon)
		btn:Dock(LEFT)
		function btn.DoClick()
			self.browser:RunJavascript[[history.back();]]
		end
	local btn = vgui.Create("DButton",self.top)
		btn:SetText("")
		btn:SetSize(24,24)
		btn:SetIcon(NextIcon)
		btn:Dock(LEFT)
		function btn.DoClick()
			self.browser:RunJavascript[[history.forward();]]
		end
		
	local entry = vgui.Create( "DTextEntry", top )
		self.entry=entry
		entry:Dock(FILL)
		entry:SetTall(  24 )
		
		function entry.OnEnter(entry)
			local val=entry:GetText()
			local js,txt = val:match("javascript:(.+)")
			if js and txt then
				self.browser:QueueJavascript(txt)
				return
			end
			self:OpenURL(val)
			self.browser:RequestFocus()
			
		end
		/*entry.Paint=function(entry,w,h)
			DTextEntry.Paint(entry,w,h)
			if self.browser:IsLoading() then
				draw.RoundedBox(h*0.5,w-h,0,h,h,Color(200,150,0,255))
			end
		end*/
	
	local btn = vgui.Create("DButton",self.top)
		btn:SetText("")
		btn:SetSize(24,24)
		btn:Dock(LEFT)
		function btn.DoClick()
			self.browser:RunJavascript[[location.reload(true);]]

		end
		
		local RefreshIcon	   = Material("icon16/arrow_refresh.png")
		local CancelIcon	   = Material("icon16/cross.png")
		btn.Paint=function(btn,w,h)
			DButton.Paint(btn,w,h)
			if not self.browser:IsLoading() then
				surface.SetDrawColor(255,255,255,255)
				surface.SetMaterial(RefreshIcon)
				surface.DrawTexturedRect(btn:GetWide()/2-16/2,btn:GetTall()/2-16/2,16,16)
			else
				--surface.SetDrawColor(240+math.sin(RealTime()*10)*15,100,50,200)
				--surface.DrawRect(1,1,w-2,h-2)
				surface.SetDrawColor(255,255,255,255)
				surface.SetMaterial(CancelIcon)
				surface.DrawTexturedRect(btn:GetWide()/2-16/2,btn:GetTall()/2-16/2,16,16)
			end
		end

		
	local btn = vgui.Create("DButton",self.top)
		btn:SetText("")
		btn:SetSize(24,24)
		btn:SetIcon("icon16/script_gear.png")
		btn:Dock(RIGHT)
		function btn.DoClick()
			self.browser:RunJavascript[[javascript:var s = document.documentElement.outerHTML; document.write('<html><body><textarea id="dsrc" style="width: 100%; height: 100%;"></textarea></body></html>');  var ta=document.getElementById( 'dsrc'); ta.value=s; void 0;]]
		end
		
	local browser = vgui.Create( "DHTML", self )
		self.browser=browser
		browser:Dock(FILL)
	browser.Paint=function() end
	browser.OpeningURL=print
	browser:SetFocusTopLevel(true)
	browser.FinishedURL=print
	browser:AddFunction( "gmod", "LoadedURL", function(url,title) self:LoadedURL(url,title) end )
	browser:AddFunction( "gmod", "dbg", function(...) Msg"[Browser] " print(...) end )
	browser:AddFunction( "console", "info", function(...) Msg"[Browser] " print(...) end )
	browser:AddFunction( "gmod", "status", function(txt) self:StatusChanged(txt) end )
	browser:AddFunction( "gmod", "reqtoken", function()
		if not GetAuthToken then
			local s=([[if ('OnAuthToken' in window) { OnAuthToken(false); };]])
			if browser:IsValid() and not browser:IsLoading() then
				browser:QueueJavascript(s)
			end
			return
		end
		
		Derma_Query("Do you want to send your auth token to this website?", "Auth Token",
			"Yes", function()
				GetAuthToken(function(dat)
					local s=([[if ('OnAuthToken' in window) { OnAuthToken("%s"); };]]):format(string.JavascriptSafe(dat))

					if browser:IsValid() and not browser:IsLoading() then
						browser:QueueJavascript(s)
					end
				end)
			end,
			"No", function() end)
	end )
	browser.ActionSignal=function(...) Msg"[BrowserACT] " print(...)  end
	browser.OnKeyCodePressed=function(browser,code)
		if code==KEY_F5 then
			self.browser:RunJavascript[[location.reload(true);]]
			return
		end
		--print("BROWSERKEY",code)
	end
	
	local status = vgui.Create( "DLabel", self )
		self.status=status
		status:SetText""
		status:Dock(BOTTOM)
end

function PANEL:StatusChanged(txt)
	if self.statustxt~=txt then
		self.statustxt=txt
		self.status:SetText(txt or "")
	end
end

function PANEL:LoadedURL(url,title)
	if self.entry:HasFocus() then return end
	self.url = url
	self.entry:SetText(url)
	self.loaded=true
	self:SetTitle(title and title~="" and title or "Web browser")
end
function PANEL:OpenURL(url)
	self.browser:OpenURL(url)
	self.entry:SetText(url)
	if self.firstload then self.firstload=nil end
end

function PANEL:Think(w,h)
	DFrame.Think(self,w,h)
	if input.IsKeyDown(KEY_ESCAPE) then
		if self.firstload then
			self:Close()
		else
			self:SetVisible(false)
		end
		if gui and gui.HideGameUI then gui.HideGameUI() end
	end
	
	
	if not self.wasloading and self.browser:IsLoading() then
		self.wasloading=true
		--print"Loading..."
	end
	if self.wasloading and not self.browser:IsLoading() then
		self.wasloading=false
		--print("WAS LOADING")
		self:_InjectScripts(self.browser)
		if self.InjectScripts then
			self:InjectScripts(self.browser)
		end
		
		--self.browser:QueueJavascript[[window.onclick = function( e ) { gmod.dbg("onclick"); }]]
		--self.browser:QueueJavascript[[window.onunload = function( e ) { gmod.dbg("onunload"); }]]
		--self.browser:QueueJavascript[[window.onbeforeunload = function( e ) { gmod.dbg("onbeforeunload"); }]]

	end
	
end

function PANEL:GetBrowser()
	return self.browser
end

function PANEL:_InjectScripts(browser)
	browser:QueueJavascript[[gmod.LoadedURL(document.location.href,document.title); gmod.status(""); ]]
	browser:QueueJavascript[[function alert(str) { console.log("Alert: "+str); }]]
	browser:QueueJavascript(fixselect)
	browser:QueueJavascript[[
		setTimeout(function() {
			document.documentElement.style.backgroundColor = 'white';
		}, 0);
		
		setTimeout(function() {
			  var elems = document.getElementsByTagName("a");
				for (var i = 0; i < elems.length; i++) {
					var dat = elems[i]['target'];
					if (dat == "_blank" || dat == "_parent"|| dat == "_top") {
						elems[i]['target'] = "_self";
					}
				}
		}, 0);
		
	]]
	

	
	browser:QueueJavascript[[
		function getLink() {
			gmod.status(this.href || "-");
		}
		function clickLink() {
			if (this.href) {
				gmod.LoadedURL(this.href,"Loading...");
			}
			gmod.status("Loading...");
		}
		var links = document.getElementsByTagName("a");
		for (i = 0; i < links.length; i++) {
			links[i].addEventListener('mouseover',getLink,false)
			links[i].addEventListener('click',clickLink,false)
		}

	]]
end

function PANEL:Show()
	if not self:IsVisible() then
		self:SetVisible(true)
		self:MakePopup()
		self:SetKeyboardInputEnabled( true )
		self:SetMouseInputEnabled( true )
	end
	if ValidPanel(self.browser) then
		self.browser:RequestFocus()
	end
	--hook.Run("OnContextMenuOpen")
	--print(self.browser.URL)
end


function PANEL:Close()
	self:SetVisible(false)
	self:Remove()
	--hook.Run("OnContextMenuClose")
end

vgui.Register(Tag,PANEL,"DFrame")


local webbrowser_panel

local function HidePanel()

	webbrowser_panel:Close()

end

local function ShowPanel(url)

	local new = false
	if not ValidPanel(webbrowser_panel) then
		new=true
		webbrowser_panel=vgui.Create(Tag)
		--_G.p=webbrowser_panel
	end
	
	webbrowser_panel:Show()
	if url and url~="" then
		webbrowser_panel:OpenURL(url)
	else
		if new then webbrowser_panel.entry:RequestFocus() end
	end
	return webbrowser_panel
end

local webbrowser_enabled = CreateClientConVar("webbrowser_enabled", "0", true)

local mediaurls = {"mp4"} -- File extensions that shouldn't be opened with ingame browser.
gui.OLDOpenURL = gui.OLDOpenURL or gui.OpenURL
function gui.OpenURL(url,useold)
	local extension = url:match(".+%.(.-)%s*$")
	
	if not webbrowser_enabled:GetBool() or useold or table.HasValue(mediaurls, extension) then
		return gui.OLDOpenURL(url)
	end
	
	
	local browser = ShowPanel(url)
	
	return browser.browser,browser
end
local function webbrowser(a,b,c,line) local url=line:gsub('^%"',""):gsub('%"$',"") ShowPanel(url) end
concommand.Add( "webbrowser", webbrowser, 	nil)
concommand.Add( "browser", webbrowser,		nil)
concommand.Add( "open", webbrowser, 		nil)