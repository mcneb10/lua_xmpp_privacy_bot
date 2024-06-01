package.preload['util.encodings'] = (function (...)
					local _ENV = _ENV;
					local function module(name, ...)
						local t = package.loaded[name] or _ENV[name] or { _NAME = name };
						package.loaded[name] = t;
						for i = 1, select("#", ...) do
							(select(i, ...))(t);
						end
						_ENV = t;
						_M = t;
						return t;
					end
				local function not_impl()
	error("Function not implemented");
end

local mime = require "mime";

module "encodings"

idna = {};
stringprep = {};
base64 = { encode = mime.b64, decode = mime.unb64 };
utf8 = {
	valid = (utf8 and utf8.len) and function (s) return not not utf8.len(s); end or function () return true; end;
};

return _M;
 end)
package.preload['util.hashes'] = (function (...)
					local _ENV = _ENV;
					local function module(name, ...)
						local t = package.loaded[name] or _ENV[name] or { _NAME = name };
						package.loaded[name] = t;
						for i = 1, select("#", ...) do
							(select(i, ...))(t);
						end
						_ENV = t;
						_M = t;
						return t;
					end
				
local function not_available(_, method_name)
	error("Hash method "..method_name.." not available", 2);
end

local _M = setmetatable({}, { __index = not_available });

local function with(mod, f)
	local ok, pkg = pcall(require, mod);
	if ok then f(pkg); end
end

with("bgcrypto.md5", function (md5)
	_M.md5 = md5.digest;
	_M.hmac_md5 = md5.hmac.digest;
end);

with("bgcrypto.sha1", function (sha1)
	_M.sha1 = sha1.digest;
	_M.hmac_sha1 = sha1.hmac.digest;
	_M.scram_Hi_sha1 = function (p, s, i) return sha1.pbkdf2(p, s, i, 20); end;
end);

with("bgcrypto.sha256", function (sha256)
	_M.sha256 = sha256.digest;
	_M.hmac_sha256 = sha256.hmac.digest;
end);

with("bgcrypto.sha512", function (sha512)
	_M.sha512 = sha512.digest;
	_M.hmac_sha512 = sha512.hmac.digest;
end);

with("sha1", function (sha1)
	_M.sha1 = function (data, hex)
		if hex then
			return sha1.sha1(data);
		else
			return (sha1.binary(data));
		end
	end;
end);

return _M;
 end)
package.preload['lib.adhoc'] = (function (...)
					local _ENV = _ENV;
					local function module(name, ...)
						local t = package.loaded[name] or _ENV[name] or { _NAME = name };
						package.loaded[name] = t;
						for i = 1, select("#", ...) do
							(select(i, ...))(t);
						end
						_ENV = t;
						_M = t;
						return t;
					end
				-- Copyright (C) 2009-2010 Florian Zeitz
--
-- This file is MIT/X11 licensed. Please see the
-- COPYING file in the source package for more information.
--

local st, uuid = require "util.stanza", require "util.uuid";

local xmlns_cmd = "http://jabber.org/protocol/commands";

local states = {}

local _M = {};

local function _cmdtag(desc, status, sessionid, action)
	local cmd = st.stanza("command", { xmlns = xmlns_cmd, node = desc.node, status = status });
	if sessionid then cmd.attr.sessionid = sessionid; end
	if action then cmd.attr.action = action; end

	return cmd;
end

function _M.new(name, node, handler, permission)
	return { name = name, node = node, handler = handler, cmdtag = _cmdtag, permission = (permission or "user") };
end

function _M.handle_cmd(command, origin, stanza)
	local sessionid = stanza.tags[1].attr.sessionid or uuid.generate();
	local dataIn = {};
	dataIn.to = stanza.attr.to;
	dataIn.from = stanza.attr.from;
	dataIn.action = stanza.tags[1].attr.action or "execute";
	dataIn.form = stanza.tags[1]:child_with_ns("jabber:x:data");

	local data, state = command:handler(dataIn, states[sessionid]);
	states[sessionid] = state;
	local stanza = st.reply(stanza);
	local cmdtag;
	if data.status == "completed" then
		states[sessionid] = nil;
		cmdtag = command:cmdtag("completed", sessionid);
	elseif data.status == "canceled" then
		states[sessionid] = nil;
		cmdtag = command:cmdtag("canceled", sessionid);
	elseif data.status == "error" then
		states[sessionid] = nil;
		stanza = st.error_reply(stanza, data.error.type, data.error.condition, data.error.message);
		origin.send(stanza);
		return true;
	else
		cmdtag = command:cmdtag("executing", sessionid);
	end

	for name, content in pairs(data) do
		if name == "info" then
			cmdtag:tag("note", {type="info"}):text(content):up();
		elseif name == "warn" then
			cmdtag:tag("note", {type="warn"}):text(content):up();
		elseif name == "error" then
			cmdtag:tag("note", {type="error"}):text(content.message):up();
		elseif name =="actions" then
			local actions = st.stanza("actions");
			for _, action in ipairs(content) do
				if (action == "prev") or (action == "next") or (action == "complete") then
					actions:tag(action):up();
				else
					module:log("error", 'Command "'..command.name..
						'" at node "'..command.node..'" provided an invalid action "'..action..'"');
				end
			end
			cmdtag:add_child(actions);
		elseif name == "form" then
			cmdtag:add_child((content.layout or content):form(content.values));
		elseif name == "result" then
			cmdtag:add_child((content.layout or content):form(content.values, "result"));
		elseif name == "other" then
			cmdtag:add_child(content);
		end
	end
	stanza:add_child(cmdtag);
	origin.send(stanza);

	return true;
end

return _M;
 end)
package.preload['util.stanza'] = (function (...)
					local _ENV = _ENV;
					local function module(name, ...)
						local t = package.loaded[name] or _ENV[name] or { _NAME = name };
						package.loaded[name] = t;
						for i = 1, select("#", ...) do
							(select(i, ...))(t);
						end
						_ENV = t;
						_M = t;
						return t;
					end
				-- Prosody IM
-- Copyright (C) 2008-2010 Matthew Wild
-- Copyright (C) 2008-2010 Waqas Hussain
--
-- This project is MIT/X11 licensed. Please see the
-- COPYING file in the source package for more information.
--


local t_insert      =  table.insert;
local t_remove      =  table.remove;
local t_concat      =  table.concat;
local s_format      = string.format;
local s_match       =  string.match;
local tostring      =      tostring;
local setmetatable  =  setmetatable;
local getmetatable  =  getmetatable;
local pairs         =         pairs;
local ipairs        =        ipairs;
local type          =          type;
local s_gsub        =   string.gsub;
local s_sub         =    string.sub;
local s_find        =   string.find;
local os            =            os;

local do_pretty_printing = not os.getenv("WINDIR");
local getstyle, getstring;
if do_pretty_printing then
	local ok, termcolours = pcall(require, "util.termcolours");
	if ok then
		getstyle, getstring = termcolours.getstyle, termcolours.getstring;
	else
		do_pretty_printing = nil;
	end
end

local xmlns_stanzas = "urn:ietf:params:xml:ns:xmpp-stanzas";

local _ENV = nil;

local stanza_mt = { __type = "stanza" };
stanza_mt.__index = stanza_mt;

local function new_stanza(name, attr)
	local stanza = { name = name, attr = attr or {}, tags = {} };
	return setmetatable(stanza, stanza_mt);
end

local function is_stanza(s)
	return getmetatable(s) == stanza_mt;
end

function stanza_mt:query(xmlns)
	return self:tag("query", { xmlns = xmlns });
end

function stanza_mt:body(text, attr)
	return self:tag("body", attr):text(text);
end

function stanza_mt:tag(name, attrs)
	local s = new_stanza(name, attrs);
	local last_add = self.last_add;
	if not last_add then last_add = {}; self.last_add = last_add; end
	(last_add[#last_add] or self):add_direct_child(s);
	t_insert(last_add, s);
	return self;
end

function stanza_mt:text(text)
	local last_add = self.last_add;
	(last_add and last_add[#last_add] or self):add_direct_child(text);
	return self;
end

function stanza_mt:up()
	local last_add = self.last_add;
	if last_add then t_remove(last_add); end
	return self;
end

function stanza_mt:reset()
	self.last_add = nil;
	return self;
end

function stanza_mt:add_direct_child(child)
	if type(child) == "table" then
		t_insert(self.tags, child);
	end
	t_insert(self, child);
end

function stanza_mt:add_child(child)
	local last_add = self.last_add;
	(last_add and last_add[#last_add] or self):add_direct_child(child);
	return self;
end

function stanza_mt:remove_children(name, xmlns)
	xmlns = xmlns or self.attr.xmlns;
	return self:maptags(function (tag)
		if (not name or tag.name == name) and tag.attr.xmlns == xmlns then
			return nil;
		end
		return tag;
	end);
end

function stanza_mt:get_child(name, xmlns)
	for _, child in ipairs(self.tags) do
		if (not name or child.name == name)
			and ((not xmlns and self.attr.xmlns == child.attr.xmlns)
				or child.attr.xmlns == xmlns) then

			return child;
		end
	end
end

function stanza_mt:get_child_text(name, xmlns)
	local tag = self:get_child(name, xmlns);
	if tag then
		return tag:get_text();
	end
	return nil;
end

function stanza_mt:child_with_name(name)
	for _, child in ipairs(self.tags) do
		if child.name == name then return child; end
	end
end

function stanza_mt:child_with_ns(ns)
	for _, child in ipairs(self.tags) do
		if child.attr.xmlns == ns then return child; end
	end
end

function stanza_mt:children()
	local i = 0;
	return function (a)
			i = i + 1
			return a[i];
		end, self, i;
end

function stanza_mt:childtags(name, xmlns)
	local tags = self.tags;
	local start_i, max_i = 1, #tags;
	return function ()
		for i = start_i, max_i do
			local v = tags[i];
			if (not name or v.name == name)
			and ((not xmlns and self.attr.xmlns == v.attr.xmlns)
				or v.attr.xmlns == xmlns) then
				start_i = i+1;
				return v;
			end
		end
	end;
end

function stanza_mt:maptags(callback)
	local tags, curr_tag = self.tags, 1;
	local n_children, n_tags = #self, #tags;

	local i = 1;
	while curr_tag <= n_tags and n_tags > 0 do
		if self[i] == tags[curr_tag] then
			local ret = callback(self[i]);
			if ret == nil then
				t_remove(self, i);
				t_remove(tags, curr_tag);
				n_children = n_children - 1;
				n_tags = n_tags - 1;
				i = i - 1;
				curr_tag = curr_tag - 1;
			else
				self[i] = ret;
				tags[curr_tag] = ret;
			end
			curr_tag = curr_tag + 1;
		end
		i = i + 1;
	end
	return self;
end

function stanza_mt:find(path)
	local pos = 1;
	local len = #path + 1;

	repeat
		local xmlns, name, text;
		local char = s_sub(path, pos, pos);
		if char == "@" then
			return self.attr[s_sub(path, pos + 1)];
		elseif char == "{" then
			xmlns, pos = s_match(path, "^([^}]+)}()", pos + 1);
		end
		name, text, pos = s_match(path, "^([^@/#]*)([/#]?)()", pos);
		name = name ~= "" and name or nil;
		if pos == len then
			if text == "#" then
				return self:get_child_text(name, xmlns);
			end
			return self:get_child(name, xmlns);
		end
		self = self:get_child(name, xmlns);
	until not self
end


local escape_table = { ["'"] = "&apos;", ["\""] = "&quot;", ["<"] = "&lt;", [">"] = "&gt;", ["&"] = "&amp;" };
local function xml_escape(str) return (s_gsub(str, "['&<>\"]", escape_table)); end

local function _dostring(t, buf, self, _xml_escape, parentns)
	local nsid = 0;
	local name = t.name
	t_insert(buf, "<"..name);
	for k, v in pairs(t.attr) do
		if s_find(k, "\1", 1, true) then
			local ns, attrk = s_match(k, "^([^\1]*)\1?(.*)$");
			nsid = nsid + 1;
			t_insert(buf, " xmlns:ns"..nsid.."='".._xml_escape(ns).."' ".."ns"..nsid..":"..attrk.."='".._xml_escape(v).."'");
		elseif not(k == "xmlns" and v == parentns) then
			t_insert(buf, " "..k.."='".._xml_escape(v).."'");
		end
	end
	local len = #t;
	if len == 0 then
		t_insert(buf, "/>");
	else
		t_insert(buf, ">");
		for n=1,len do
			local child = t[n];
			if child.name then
				self(child, buf, self, _xml_escape, t.attr.xmlns);
			else
				t_insert(buf, _xml_escape(child));
			end
		end
		t_insert(buf, "</"..name..">");
	end
end
function stanza_mt.__tostring(t)
	local buf = {};
	_dostring(t, buf, _dostring, xml_escape, nil);
	return t_concat(buf);
end

function stanza_mt.top_tag(t)
	local attr_string = "";
	if t.attr then
		for k, v in pairs(t.attr) do if type(k) == "string" then attr_string = attr_string .. s_format(" %s='%s'", k, xml_escape(tostring(v))); end end
	end
	return s_format("<%s%s>", t.name, attr_string);
end

function stanza_mt.get_text(t)
	if #t.tags == 0 then
		return t_concat(t);
	end
end

function stanza_mt.get_error(stanza)
	local error_type, condition, text;

	local error_tag = stanza:get_child("error");
	if not error_tag then
		return nil, nil, nil;
	end
	error_type = error_tag.attr.type;

	for _, child in ipairs(error_tag.tags) do
		if child.attr.xmlns == xmlns_stanzas then
			if not text and child.name == "text" then
				text = child:get_text();
			elseif not condition then
				condition = child.name;
			end
			if condition and text then
				break;
			end
		end
	end
	return error_type, condition or "undefined-condition", text;
end

local id = 0;
local function new_id()
	id = id + 1;
	return "lx"..id;
end

local function preserialize(stanza)
	local s = { name = stanza.name, attr = stanza.attr };
	for _, child in ipairs(stanza) do
		if type(child) == "table" then
			t_insert(s, preserialize(child));
		else
			t_insert(s, child);
		end
	end
	return s;
end

local function deserialize(stanza)
	-- Set metatable
	if stanza then
		local attr = stanza.attr;
		for i=1,#attr do attr[i] = nil; end
		local attrx = {};
		for att in pairs(attr) do
			if s_find(att, "|", 1, true) and not s_find(att, "\1", 1, true) then
				local ns,na = s_match(att, "^([^|]+)|(.+)$");
				attrx[ns.."\1"..na] = attr[att];
				attr[att] = nil;
			end
		end
		for a,v in pairs(attrx) do
			attr[a] = v;
		end
		setmetatable(stanza, stanza_mt);
		for _, child in ipairs(stanza) do
			if type(child) == "table" then
				deserialize(child);
			end
		end
		if not stanza.tags then
			-- Rebuild tags
			local tags = {};
			for _, child in ipairs(stanza) do
				if type(child) == "table" then
					t_insert(tags, child);
				end
			end
			stanza.tags = tags;
		end
	end

	return stanza;
end

local function clone(stanza)
	local attr, tags = {}, {};
	for k,v in pairs(stanza.attr) do attr[k] = v; end
	local new = { name = stanza.name, attr = attr, tags = tags };
	for i=1,#stanza do
		local child = stanza[i];
		if child.name then
			child = clone(child);
			t_insert(tags, child);
		end
		t_insert(new, child);
	end
	return setmetatable(new, stanza_mt);
end

local function message(attr, body)
	if not body then
		return new_stanza("message", attr);
	else
		return new_stanza("message", attr):tag("body"):text(body):up();
	end
end
local function iq(attr)
	if attr and not attr.id then attr.id = new_id(); end
	return new_stanza("iq", attr or { id = new_id() });
end

local function reply(orig)
	return new_stanza(orig.name, orig.attr and { to = orig.attr.from, from = orig.attr.to, id = orig.attr.id, type = ((orig.name == "iq" and "result") or orig.attr.type) });
end

local xmpp_stanzas_attr = { xmlns = xmlns_stanzas };
local function error_reply(orig, error_type, condition, error_message)
	local t = reply(orig);
	t.attr.type = "error";
	t:tag("error", {type = error_type}) --COMPAT: Some day xmlns:stanzas goes here
	:tag(condition, xmpp_stanzas_attr):up();
	if error_message then t:tag("text", xmpp_stanzas_attr):text(error_message):up(); end
	return t; -- stanza ready for adding app-specific errors
end

local function presence(attr)
	return new_stanza("presence", attr);
end

if do_pretty_printing then
	local style_attrk = getstyle("yellow");
	local style_attrv = getstyle("red");
	local style_tagname = getstyle("red");
	local style_punc = getstyle("magenta");

	local attr_format = " "..getstring(style_attrk, "%s")..getstring(style_punc, "=")..getstring(style_attrv, "'%s'");
	local top_tag_format = getstring(style_punc, "<")..getstring(style_tagname, "%s").."%s"..getstring(style_punc, ">");
	--local tag_format = getstring(style_punc, "<")..getstring(style_tagname, "%s").."%s"..getstring(style_punc, ">").."%s"..getstring(style_punc, "</")..getstring(style_tagname, "%s")..getstring(style_punc, ">");
	local tag_format = top_tag_format.."%s"..getstring(style_punc, "</")..getstring(style_tagname, "%s")..getstring(style_punc, ">");
	function stanza_mt.pretty_print(t)
		local children_text = "";
		for _, child in ipairs(t) do
			if type(child) == "string" then
				children_text = children_text .. xml_escape(child);
			else
				children_text = children_text .. child:pretty_print();
			end
		end

		local attr_string = "";
		if t.attr then
			for k, v in pairs(t.attr) do if type(k) == "string" then attr_string = attr_string .. s_format(attr_format, k, tostring(v)); end end
		end
		return s_format(tag_format, t.name, attr_string, children_text, t.name);
	end

	function stanza_mt.pretty_top_tag(t)
		local attr_string = "";
		if t.attr then
			for k, v in pairs(t.attr) do if type(k) == "string" then attr_string = attr_string .. s_format(attr_format, k, tostring(v)); end end
		end
		return s_format(top_tag_format, t.name, attr_string);
	end
else
	-- Sorry, fresh out of colours for you guys ;)
	stanza_mt.pretty_print = stanza_mt.__tostring;
	stanza_mt.pretty_top_tag = stanza_mt.top_tag;
end

return {
	stanza_mt = stanza_mt;
	stanza = new_stanza;
	is_stanza = is_stanza;
	new_id = new_id;
	preserialize = preserialize;
	deserialize = deserialize;
	clone = clone;
	message = message;
	iq = iq;
	reply = reply;
	error_reply = error_reply;
	presence = presence;
	xml_escape = xml_escape;
};
 end)
package.preload['util.timer'] = (function (...)
					local _ENV = _ENV;
					local function module(name, ...)
						local t = package.loaded[name] or _ENV[name] or { _NAME = name };
						package.loaded[name] = t;
						for i = 1, select("#", ...) do
							(select(i, ...))(t);
						end
						_ENV = t;
						_M = t;
						return t;
					end
				-- Prosody IM
-- Copyright (C) 2008-2010 Matthew Wild
-- Copyright (C) 2008-2010 Waqas Hussain
--
-- This project is MIT/X11 licensed. Please see the
-- COPYING file in the source package for more information.
--

local server = require "net.server";
local math_min = math.min
local math_huge = math.huge
local get_time = require "util.time".now
local t_insert = table.insert;
local pairs = pairs;
local type = type;

local data = {};
local new_data = {};

local _ENV = nil;

local _add_task;
if not server.event then
	function _add_task(delay, callback)
		local current_time = get_time();
		delay = delay + current_time;
		if delay >= current_time then
			t_insert(new_data, {delay, callback});
		else
			local r = callback(current_time);
			if r and type(r) == "number" then
				return _add_task(r, callback);
			end
		end
	end

	server._addtimer(function()
		local current_time = get_time();
		if #new_data > 0 then
			for _, d in pairs(new_data) do
				t_insert(data, d);
			end
			new_data = {};
		end

		local next_time = math_huge;
		for i, d in pairs(data) do
			local t, callback = d[1], d[2];
			if t <= current_time then
				data[i] = nil;
				local r = callback(current_time);
				if type(r) == "number" then
					_add_task(r, callback);
					next_time = math_min(next_time, r);
				end
			else
				next_time = math_min(next_time, t - current_time);
			end
		end
		return next_time;
	end);
else
	local event = server.event;
	local event_base = server.event_base;
	local EVENT_LEAVE = (event.core and event.core.LEAVE) or -1;

	function _add_task(delay, callback)
		local event_handle;
		event_handle = event_base:addevent(nil, 0, function ()
			local ret = callback(get_time());
			if ret then
				return 0, ret;
			elseif event_handle then
				return EVENT_LEAVE;
			end
		end
		, delay);
	end
end

return {
	add_task = _add_task;
};
 end)
package.preload['util.termcolours'] = (function (...)
					local _ENV = _ENV;
					local function module(name, ...)
						local t = package.loaded[name] or _ENV[name] or { _NAME = name };
						package.loaded[name] = t;
						for i = 1, select("#", ...) do
							(select(i, ...))(t);
						end
						_ENV = t;
						_M = t;
						return t;
					end
				-- Prosody IM
-- Copyright (C) 2008-2010 Matthew Wild
-- Copyright (C) 2008-2010 Waqas Hussain
--
-- This project is MIT/X11 licensed. Please see the
-- COPYING file in the source package for more information.
--
--
-- luacheck: ignore 213/i


local t_concat, t_insert = table.concat, table.insert;
local char, format = string.char, string.format;
local tonumber = tonumber;
local ipairs = ipairs;
local io_write = io.write;
local m_floor = math.floor;
local type = type;
local setmetatable = setmetatable;
local pairs = pairs;

local windows;
if os.getenv("WINDIR") then
	windows = require "util.windows";
end
local orig_color = windows and windows.get_consolecolor and windows.get_consolecolor();

local _ENV = nil;

local stylemap = {
			reset = 0; bright = 1, dim = 2, underscore = 4, blink = 5, reverse = 7, hidden = 8;
			black = 30; red = 31; green = 32; yellow = 33; blue = 34; magenta = 35; cyan = 36; white = 37;
			["black background"] = 40; ["red background"] = 41; ["green background"] = 42; ["yellow background"] = 43;
			["blue background"] = 44; ["magenta background"] = 45; ["cyan background"] = 46; ["white background"] = 47;
			bold = 1, dark = 2, underline = 4, underlined = 4, normal = 0;
		}

local winstylemap = {
	["0"] = orig_color, -- reset
	["1"] = 7+8, -- bold
	["1;33"] = 2+4+8, -- bold yellow
	["1;31"] = 4+8 -- bold red
}

local cssmap = {
	[1] = "font-weight: bold", [2] = "opacity: 0.5", [4] = "text-decoration: underline", [8] = "visibility: hidden",
	[30] = "color:black", [31] = "color:red", [32]="color:green", [33]="color:#FFD700",
	[34] = "color:blue", [35] = "color: magenta", [36] = "color:cyan", [37] = "color: white",
	[40] = "background-color:black", [41] = "background-color:red", [42]="background-color:green",
	[43]="background-color:yellow",	[44] = "background-color:blue", [45] = "background-color: magenta",
	[46] = "background-color:cyan", [47] = "background-color: white";
};

local fmt_string = char(0x1B).."[%sm%s"..char(0x1B).."[0m";
local function getstring(style, text)
	if style then
		return format(fmt_string, style, text);
	else
		return text;
	end
end

local function gray(n)
	return m_floor(n*3/32)+0xe8;
end
local function color(r,g,b)
	if r == g and g == b then
		return gray(r);
	end
	r = m_floor(r*3/128);
	g = m_floor(g*3/128);
	b = m_floor(b*3/128);
	return 0x10 + ( r * 36 ) + ( g * 6 ) + ( b );
end
local function hex2rgb(hex)
	local r = tonumber(hex:sub(1,2),16);
	local g = tonumber(hex:sub(3,4),16);
	local b = tonumber(hex:sub(5,6),16);
	return r,g,b;
end

setmetatable(stylemap, { __index = function(_, style)
	if type(style) == "string" and style:find("%x%x%x%x%x%x") == 1 then
		local g = style:sub(7) == " background" and "48;5;" or "38;5;";
		return g .. color(hex2rgb(style));
	end
end } );

local csscolors = {
	red = "ff0000"; fuchsia = "ff00ff"; green = "008000"; white = "ffffff";
	lime = "00ff00"; yellow = "ffff00"; purple = "800080"; blue = "0000ff";
	aqua = "00ffff"; olive  = "808000"; black  = "000000"; navy = "000080";
	teal = "008080"; silver = "c0c0c0"; maroon = "800000"; gray = "808080";
}
for colorname, rgb in pairs(csscolors) do
	stylemap[colorname] = stylemap[colorname] or stylemap[rgb];
	colorname, rgb = colorname .. " background", rgb .. " background"
	stylemap[colorname] = stylemap[colorname] or stylemap[rgb];
end

local function getstyle(...)
	local styles, result = { ... }, {};
	for i, style in ipairs(styles) do
		style = stylemap[style];
		if style then
			t_insert(result, style);
		end
	end
	return t_concat(result, ";");
end

local last = "0";
local function setstyle(style)
	style = style or "0";
	if style ~= last then
		io_write("\27["..style.."m");
		last = style;
	end
end

if windows then
	function setstyle(style)
		style = style or "0";
		if style ~= last then
			windows.set_consolecolor(winstylemap[style] or orig_color);
			last = style;
		end
	end
	if not orig_color then
		function setstyle() end
	end
end

local function ansi2css(ansi_codes)
	if ansi_codes == "0" then return "</span>"; end
	local css = {};
	for code in ansi_codes:gmatch("[^;]+") do
		t_insert(css, cssmap[tonumber(code)]);
	end
	return "</span><span style='"..t_concat(css, ";").."'>";
end

local function tohtml(input)
	return input:gsub("\027%[(.-)m", ansi2css);
end

return {
	getstring = getstring;
	getstyle = getstyle;
	setstyle = setstyle;
	tohtml = tohtml;
};
 end)
package.preload['util.uuid'] = (function (...)
					local _ENV = _ENV;
					local function module(name, ...)
						local t = package.loaded[name] or _ENV[name] or { _NAME = name };
						package.loaded[name] = t;
						for i = 1, select("#", ...) do
							(select(i, ...))(t);
						end
						_ENV = t;
						_M = t;
						return t;
					end
				-- Prosody IM
-- Copyright (C) 2008-2010 Matthew Wild
-- Copyright (C) 2008-2010 Waqas Hussain
--
-- This project is MIT/X11 licensed. Please see the
-- COPYING file in the source package for more information.
--

local random = require "util.random";
local random_bytes = random.bytes;
local hex = require "util.hex".to;
local m_ceil = math.ceil;

local function get_nibbles(n)
	return hex(random_bytes(m_ceil(n/2))):sub(1, n);
end

local function get_twobits()
	return ("%x"):format(random_bytes(1):byte() % 4 + 8);
end

local function generate()
	-- generate RFC 4122 complaint UUIDs (version 4 - random)
	return get_nibbles(8).."-"..get_nibbles(4).."-4"..get_nibbles(3).."-"..(get_twobits())..get_nibbles(3).."-"..get_nibbles(12);
end

return {
	get_nibbles=get_nibbles;
	generate = generate ;
	-- COMPAT
	seed = random.seed;
};
 end)
package.preload['net.dns'] = (function (...)
					local _ENV = _ENV;
					local function module(name, ...)
						local t = package.loaded[name] or _ENV[name] or { _NAME = name };
						package.loaded[name] = t;
						for i = 1, select("#", ...) do
							(select(i, ...))(t);
						end
						_ENV = t;
						_M = t;
						return t;
					end
				-- Prosody IM
-- This file is included with Prosody IM. It has modifications,
-- which are hereby placed in the public domain.


-- todo: quick (default) header generation
-- todo: nxdomain, error handling
-- todo: cache results of encodeName


-- reference: http://tools.ietf.org/html/rfc1035
-- reference: http://tools.ietf.org/html/rfc1876 (LOC)


local socket = require "socket";
local timer = require "util.timer";
local new_ip = require "util.ip".new_ip;

local _, windows = pcall(require, "util.windows");
local is_windows = (_ and windows) or os.getenv("WINDIR");

local coroutine, io, math, string, table =
      coroutine, io, math, string, table;

local ipairs, next, pairs, print, setmetatable, tostring, assert, error, select, type =
      ipairs, next, pairs, print, setmetatable, tostring, assert, error, select, type;

local ztact = { -- public domain 20080404 lua@ztact.com
	get = function(parent, ...)
		local len = select('#', ...);
		for i=1,len do
			parent = parent[select(i, ...)];
			if parent == nil then break; end
		end
		return parent;
	end;
	set = function(parent, ...)
		local len = select('#', ...);
		local key, value = select(len-1, ...);
		local cutpoint, cutkey;

		for i=1,len-2 do
			local key = select (i, ...)
			local child = parent[key]

			if value == nil then
				if child == nil then
					return;
				elseif next(child, next(child)) then
					cutpoint = nil; cutkey = nil;
				elseif cutpoint == nil then
					cutpoint = parent; cutkey = key;
				end
			elseif child == nil then
				child = {};
				parent[key] = child;
			end
			parent = child
		end

		if value == nil and cutpoint then
			cutpoint[cutkey] = nil;
		else
			parent[key] = value;
			return value;
		end
	end;
};
local get, set = ztact.get, ztact.set;

local default_timeout = 15;

-------------------------------------------------- module dns
local _ENV = nil;
local dns = {};


-- dns type & class codes ------------------------------ dns type & class codes


local append = table.insert


local function highbyte(i)    -- - - - - - - - - - - - - - - - - - -  highbyte
	return (i-(i%0x100))/0x100;
end


local function augment (t, prefix)  -- - - - - - - - - - - - - - - - -  augment
	local a = {};
	for i,s in pairs(t) do
		a[i] = s;
		a[s] = s;
		a[string.lower(s)] = s;
	end
	setmetatable(a, {
		__index = function (_, i)
			if type(i) == "number" then
				return ("%s%d"):format(prefix, i);
			elseif type(i) == "string" then
				return i:upper();
			end
		end;
	})
	return a;
end


local function encode (t)    -- - - - - - - - - - - - - - - - - - - - -  encode
	local code = {};
	for i,s in pairs(t) do
		local word = string.char(highbyte(i), i%0x100);
		code[i] = word;
		code[s] = word;
		code[string.lower(s)] = word;
	end
	return code;
end


dns.types = {
	'A', 'NS', 'MD', 'MF', 'CNAME', 'SOA', 'MB', 'MG', 'MR', 'NULL', 'WKS',
	'PTR', 'HINFO', 'MINFO', 'MX', 'TXT',
	[ 28] = 'AAAA', [ 29] = 'LOC',   [ 33] = 'SRV',
	[252] = 'AXFR', [253] = 'MAILB', [254] = 'MAILA', [255] = '*' };


dns.classes = { 'IN', 'CS', 'CH', 'HS', [255] = '*' };


dns.type      = augment (dns.types, "TYPE");
dns.class     = augment (dns.classes, "CLASS");
dns.typecode  = encode  (dns.types);
dns.classcode = encode  (dns.classes);



local function standardize(qname, qtype, qclass)    -- - - - - - - standardize
	if string.byte(qname, -1) ~= 0x2E then qname = qname..'.';  end
	qname = string.lower(qname);
	return qname, dns.type[qtype or 'A'], dns.class[qclass or 'IN'];
end


local function prune(rrs, time, soft)    -- - - - - - - - - - - - - - -  prune
	time = time or socket.gettime();
	for i,rr in ipairs(rrs) do
		if rr.tod then
			if rr.tod < time then
				rrs[rr[rr.type:lower()]] = nil;
				table.remove(rrs, i);
				return prune(rrs, time, soft); -- Re-iterate
			end
		elseif soft == 'soft' then    -- What is this?  I forget!
			assert(rr.ttl == 0);
			rrs[rr[rr.type:lower()]] = nil;
			table.remove(rrs, i);
		end
	end
end


-- metatables & co. ------------------------------------------ metatables & co.


local resolver = {};
resolver.__index = resolver;

resolver.timeout = default_timeout;

local function default_rr_tostring(rr)
	local rr_val = rr.type and rr[rr.type:lower()];
	if type(rr_val) ~= "string" then
		return "<UNKNOWN RDATA TYPE>";
	end
	return rr_val;
end

local special_tostrings = {
	LOC = resolver.LOC_tostring;
	MX  = function (rr)
		return string.format('%2i %s', rr.pref, rr.mx);
	end;
	SRV = function (rr)
		local s = rr.srv;
		return string.format('%5d %5d %5d %s', s.priority, s.weight, s.port, s.target);
	end;
};

local rr_metatable = {};   -- - - - - - - - - - - - - - - - - - -  rr_metatable
function rr_metatable.__tostring(rr)
	local rr_string = (special_tostrings[rr.type] or default_rr_tostring)(rr);
	return string.format('%2s %-5s %6i %-28s %s', rr.class, rr.type, rr.ttl, rr.name, rr_string);
end


local rrs_metatable = {};    -- - - - - - - - - - - - - - - - - -  rrs_metatable
function rrs_metatable.__tostring(rrs)
	local t = {};
	for _, rr in ipairs(rrs) do
		append(t, tostring(rr)..'\n');
	end
	return table.concat(t);
end


local cache_metatable = {};    -- - - - - - - - - - - - - - - -  cache_metatable
function cache_metatable.__tostring(cache)
	local time = socket.gettime();
	local t = {};
	for class,types in pairs(cache) do
		for type,names in pairs(types) do
			for name,rrs in pairs(names) do
				prune(rrs, time);
				append(t, tostring(rrs));
			end
		end
	end
	return table.concat(t);
end


-- packet layer -------------------------------------------------- packet layer


function dns.random(...)    -- - - - - - - - - - - - - - - - - - -  dns.random
	math.randomseed(math.floor(10000*socket.gettime()) % 0x80000000);
	dns.random = math.random;
	return dns.random(...);
end


local function encodeHeader(o)    -- - - - - - - - - - - - - - -  encodeHeader
	o = o or {};
	o.id = o.id or dns.random(0, 0xffff); -- 16b	(random) id

	o.rd = o.rd or 1;		--  1b  1 recursion desired
	o.tc = o.tc or 0;		--  1b	1 truncated response
	o.aa = o.aa or 0;		--  1b	1 authoritative response
	o.opcode = o.opcode or 0;	--  4b	0 query
				--  1 inverse query
				--	2 server status request
				--	3-15 reserved
	o.qr = o.qr or 0;		--  1b	0 query, 1 response

	o.rcode = o.rcode or 0;	--  4b  0 no error
				--	1 format error
				--	2 server failure
				--	3 name error
				--	4 not implemented
				--	5 refused
				--	6-15 reserved
	o.z = o.z  or 0;		--  3b  0 resvered
	o.ra = o.ra or 0;		--  1b  1 recursion available

	o.qdcount = o.qdcount or 1;	-- 16b	number of question RRs
	o.ancount = o.ancount or 0;	-- 16b	number of answers RRs
	o.nscount = o.nscount or 0;	-- 16b	number of nameservers RRs
	o.arcount = o.arcount or 0;	-- 16b  number of additional RRs

	-- string.char() rounds, so prevent roundup with -0.4999
	local header = string.char(
		highbyte(o.id), o.id %0x100,
		o.rd + 2*o.tc + 4*o.aa + 8*o.opcode + 128*o.qr,
		o.rcode + 16*o.z + 128*o.ra,
		highbyte(o.qdcount),  o.qdcount %0x100,
		highbyte(o.ancount),  o.ancount %0x100,
		highbyte(o.nscount),  o.nscount %0x100,
		highbyte(o.arcount),  o.arcount %0x100
	);

	return header, o.id;
end


local function encodeName(name)    -- - - - - - - - - - - - - - - - encodeName
	local t = {};
	for part in string.gmatch(name, '[^.]+') do
		append(t, string.char(string.len(part)));
		append(t, part);
	end
	append(t, string.char(0));
	return table.concat(t);
end


local function encodeQuestion(qname, qtype, qclass)    -- - - - encodeQuestion
	qname  = encodeName(qname);
	qtype  = dns.typecode[qtype or 'a'];
	qclass = dns.classcode[qclass or 'in'];
	return qname..qtype..qclass;
end


function resolver:byte(len)    -- - - - - - - - - - - - - - - - - - - - - byte
	len = len or 1;
	local offset = self.offset;
	local last = offset + len - 1;
	if last > #self.packet then
		error(string.format('out of bounds: %i>%i', last, #self.packet));
	end
	self.offset = offset + len;
	return string.byte(self.packet, offset, last);
end


function resolver:word()    -- - - - - - - - - - - - - - - - - - - - - -  word
	local b1, b2 = self:byte(2);
	return 0x100*b1 + b2;
end


function resolver:dword ()    -- - - - - - - - - - - - - - - - - - - - -  dword
	local b1, b2, b3, b4 = self:byte(4);
	--print('dword', b1, b2, b3, b4);
	return 0x1000000*b1 + 0x10000*b2 + 0x100*b3 + b4;
end


function resolver:sub(len)    -- - - - - - - - - - - - - - - - - - - - - - sub
	len = len or 1;
	local s = string.sub(self.packet, self.offset, self.offset + len - 1);
	self.offset = self.offset + len;
	return s;
end


function resolver:header(force)    -- - - - - - - - - - - - - - - - - - header
	local id = self:word();
	--print(string.format(':header  id  %x', id));
	if not self.active[id] and not force then return nil; end

	local h = { id = id };

	local b1, b2 = self:byte(2);

	h.rd      = b1 %2;
	h.tc      = b1 /2%2;
	h.aa      = b1 /4%2;
	h.opcode  = b1 /8%16;
	h.qr      = b1 /128;

	h.rcode   = b2 %16;
	h.z       = b2 /16%8;
	h.ra      = b2 /128;

	h.qdcount = self:word();
	h.ancount = self:word();
	h.nscount = self:word();
	h.arcount = self:word();

	for k,v in pairs(h) do h[k] = v-v%1; end

	return h;
end


function resolver:name()    -- - - - - - - - - - - - - - - - - - - - - -  name
	local remember, pointers = nil, 0;
	local len = self:byte();
	local n = {};
	if len == 0 then return "." end -- Root label
	while len > 0 do
		if len >= 0xc0 then    -- name is "compressed"
			pointers = pointers + 1;
			if pointers >= 20 then error('dns error: 20 pointers'); end;
			local offset = ((len-0xc0)*0x100) + self:byte();
			remember = remember or self.offset;
			self.offset = offset + 1;    -- +1 for lua
		else    -- name is not compressed
			append(n, self:sub(len)..'.');
		end
		len = self:byte();
	end
	self.offset = remember or self.offset;
	return table.concat(n);
end


function resolver:question()    -- - - - - - - - - - - - - - - - - -  question
	local q = {};
	q.name  = self:name();
	q.type  = dns.type[self:word()];
	q.class = dns.class[self:word()];
	return q;
end


function resolver:A(rr)    -- - - - - - - - - - - - - - - - - - - - - - - -  A
	local b1, b2, b3, b4 = self:byte(4);
	rr.a = string.format('%i.%i.%i.%i', b1, b2, b3, b4);
end

function resolver:AAAA(rr)
	local addr = {};
	for _ = 1, rr.rdlength, 2 do
		local b1, b2 = self:byte(2);
		table.insert(addr, ("%02x%02x"):format(b1, b2));
	end
	addr = table.concat(addr, ":"):gsub("%f[%x]0+(%x)","%1");
	local zeros = {};
	for item in addr:gmatch(":[0:]+:[0:]+:") do
		table.insert(zeros, item)
	end
	if #zeros == 0 then
		rr.aaaa = addr;
		return
	elseif #zeros > 1 then
		table.sort(zeros, function(a, b) return #a > #b end);
	end
	rr.aaaa = addr:gsub(zeros[1], "::", 1):gsub("^0::", "::"):gsub("::0$", "::");
end

function resolver:CNAME(rr)    -- - - - - - - - - - - - - - - - - - - -  CNAME
	rr.cname = self:name();
end


function resolver:MX(rr)    -- - - - - - - - - - - - - - - - - - - - - - -  MX
	rr.pref = self:word();
	rr.mx   = self:name();
end


function resolver:LOC_nibble_power()    -- - - - - - - - - -  LOC_nibble_power
	local b = self:byte();
	--print('nibbles', ((b-(b%0x10))/0x10), (b%0x10));
	return ((b-(b%0x10))/0x10) * (10^(b%0x10));
end


function resolver:LOC(rr)    -- - - - - - - - - - - - - - - - - - - - - -  LOC
	rr.version = self:byte();
	if rr.version == 0 then
		rr.loc           = rr.loc or {};
		rr.loc.size      = self:LOC_nibble_power();
		rr.loc.horiz_pre = self:LOC_nibble_power();
		rr.loc.vert_pre  = self:LOC_nibble_power();
		rr.loc.latitude  = self:dword();
		rr.loc.longitude = self:dword();
		rr.loc.altitude  = self:dword();
	end
end


local function LOC_tostring_degrees(f, pos, neg)    -- - - - - - - - - - - - -
	f = f - 0x80000000;
	if f < 0 then pos = neg; f = -f; end
	local deg, min, msec;
	msec = f%60000;
	f    = (f-msec)/60000;
	min  = f%60;
	deg = (f-min)/60;
	return string.format('%3d %2d %2.3f %s', deg, min, msec/1000, pos);
end


function resolver.LOC_tostring(rr)    -- - - - - - - - - - - - -  LOC_tostring
	local t = {};

	--[[
	for k,name in pairs { 'size', 'horiz_pre', 'vert_pre', 'latitude', 'longitude', 'altitude' } do
		append(t, string.format('%4s%-10s: %12.0f\n', '', name, rr.loc[name]));
	end
	--]]

	append(t, string.format(
		'%s    %s    %.2fm %.2fm %.2fm %.2fm',
		LOC_tostring_degrees (rr.loc.latitude, 'N', 'S'),
		LOC_tostring_degrees (rr.loc.longitude, 'E', 'W'),
		(rr.loc.altitude - 10000000) / 100,
		rr.loc.size / 100,
		rr.loc.horiz_pre / 100,
		rr.loc.vert_pre / 100
	));

	return table.concat(t);
end


function resolver:NS(rr)    -- - - - - - - - - - - - - - - - - - - - - - -  NS
	rr.ns = self:name();
end


function resolver:SOA(rr)    -- - - - - - - - - - - - - - - - - - - - - -  SOA
end


function resolver:SRV(rr)    -- - - - - - - - - - - - - - - - - - - - - -  SRV
	  rr.srv = {};
	  rr.srv.priority = self:word();
	  rr.srv.weight   = self:word();
	  rr.srv.port     = self:word();
	  rr.srv.target   = self:name();
end

function resolver:PTR(rr)
	rr.ptr = self:name();
end

function resolver:TXT(rr)    -- - - - - - - - - - - - - - - - - - - - - -  TXT
	rr.txt = self:sub (self:byte());
end


function resolver:rr()    -- - - - - - - - - - - - - - - - - - - - - - - -  rr
	local rr = {};
	setmetatable(rr, rr_metatable);
	rr.name     = self:name(self);
	rr.type     = dns.type[self:word()] or rr.type;
	rr.class    = dns.class[self:word()] or rr.class;
	rr.ttl      = 0x10000*self:word() + self:word();
	rr.rdlength = self:word();

	rr.tod = self.time + math.max(rr.ttl, 1);

	local remember = self.offset;
	local rr_parser = self[dns.type[rr.type]];
	if rr_parser then rr_parser(self, rr); end
	self.offset = remember;
	rr.rdata = self:sub(rr.rdlength);
	return rr;
end


function resolver:rrs (count)    -- - - - - - - - - - - - - - - - - - - - - rrs
	local rrs = {};
	for _ = 1, count do append(rrs, self:rr()); end
	return rrs;
end


function resolver:decode(packet, force)    -- - - - - - - - - - - - - - decode
	self.packet, self.offset = packet, 1;
	local header = self:header(force);
	if not header then return nil; end
	local response = { header = header };

	response.question = {};
	local offset = self.offset;
	for _ = 1, response.header.qdcount do
		append(response.question, self:question());
	end
	response.question.raw = string.sub(self.packet, offset, self.offset - 1);

	if not force then
		if not self.active[response.header.id] or not self.active[response.header.id][response.question.raw] then
			self.active[response.header.id] = nil;
			return nil;
		end
	end

	response.answer     = self:rrs(response.header.ancount);
	response.authority  = self:rrs(response.header.nscount);
	response.additional = self:rrs(response.header.arcount);

	return response;
end


-- socket layer -------------------------------------------------- socket layer


resolver.delays = { 1, 3 };


function resolver:addnameserver(address)    -- - - - - - - - - - addnameserver
	self.server = self.server or {};
	append(self.server, address);
end


function resolver:setnameserver(address)    -- - - - - - - - - - setnameserver
	self.server = {};
	self:addnameserver(address);
end


function resolver:adddefaultnameservers()    -- - - - -  adddefaultnameservers
	if is_windows then
		if windows and windows.get_nameservers then
			for _, server in ipairs(windows.get_nameservers()) do
				self:addnameserver(server);
			end
		end
		if not self.server or #self.server == 0 then
			-- TODO log warning about no nameservers, adding opendns servers as fallback
			self:addnameserver("208.67.222.222");
			self:addnameserver("208.67.220.220");
		end
	else -- posix
		local resolv_conf = io.open("/etc/resolv.conf");
		if resolv_conf then
			for line in resolv_conf:lines() do
				line = line:gsub("#.*$", "")
					:match('^%s*nameserver%s+([%x:%.]*%%?%S*)%s*$');
				if line then
					local ip = new_ip(line);
					if ip then
						self:addnameserver(ip.addr);
					end
				end
			end
		end
		if not self.server or #self.server == 0 then
			-- TODO log warning about no nameservers, adding localhost as the default nameserver
			self:addnameserver("127.0.0.1");
		end
	end
end


function resolver:getsocket(servernum)    -- - - - - - - - - - - - - getsocket
	self.socket = self.socket or {};
	self.socketset = self.socketset or {};

	local sock = self.socket[servernum];
	if sock then return sock; end

	local ok, err;
	local peer = self.server[servernum];
	if peer:find(":") then
		sock, err = socket.udp6();
	else
		sock, err = (socket.udp4 or socket.udp)();
	end
	if sock and self.socket_wrapper then sock, err = self.socket_wrapper(sock, self); end
	if not sock then
		return nil, err;
	end
	sock:settimeout(0);
	-- todo: attempt to use a random port, fallback to 0
	self.socket[servernum] = sock;
	self.socketset[sock] = servernum;
	-- set{sock,peer}name can fail, eg because of local routing table
	-- if so, try the next server
	ok, err = sock:setsockname('*', 0);
	if not ok then return self:servfail(sock, err); end
	ok, err = sock:setpeername(peer, 53);
	if not ok then return self:servfail(sock, err); end
	return sock;
end

function resolver:voidsocket(sock)
	if self.socket[sock] then
		self.socketset[self.socket[sock]] = nil;
		self.socket[sock] = nil;
	elseif self.socketset[sock] then
		self.socket[self.socketset[sock]] = nil;
		self.socketset[sock] = nil;
	end
	sock:close();
end

function resolver:socket_wrapper_set(func)  -- - - - - - - socket_wrapper_set
	self.socket_wrapper = func;
end


function resolver:closeall ()    -- - - - - - - - - - - - - - - - - -  closeall
	for i,sock in ipairs(self.socket) do
		self.socket[i] = nil;
		self.socketset[sock] = nil;
		sock:close();
	end
end


function resolver:remember(rr, type)    -- - - - - - - - - - - - - -  remember
	--print ('remember', type, rr.class, rr.type, rr.name)
	local qname, qtype, qclass = standardize(rr.name, rr.type, rr.class);

	if type ~= '*' then
		type = qtype;
		local all = get(self.cache, qclass, '*', qname);
		--print('remember all', all);
		if all then append(all, rr); end
	end

	self.cache = self.cache or setmetatable({}, cache_metatable);
	local rrs = get(self.cache, qclass, type, qname) or
		set(self.cache, qclass, type, qname, setmetatable({}, rrs_metatable));
	if rr[qtype:lower()] and not rrs[rr[qtype:lower()]] then
		rrs[rr[qtype:lower()]] = true;
		append(rrs, rr);
	end

	if type == 'MX' then self.unsorted[rrs] = true; end
end


local function comp_mx(a, b)    -- - - - - - - - - - - - - - - - - - - comp_mx
	return (a.pref == b.pref) and (a.mx < b.mx) or (a.pref < b.pref);
end


function resolver:peek (qname, qtype, qclass, n)    -- - - - - - - - - - - -  peek
	qname, qtype, qclass = standardize(qname, qtype, qclass);
	local rrs = get(self.cache, qclass, qtype, qname);
	if not rrs then
		if n then if n <= 0 then return end else n = 3 end
		rrs = get(self.cache, qclass, "CNAME", qname);
		if not (rrs and rrs[1]) then return end
		return self:peek(rrs[1].cname, qtype, qclass, n - 1);
	end
	if prune(rrs, socket.gettime()) and qtype == '*' or not next(rrs) then
		set(self.cache, qclass, qtype, qname, nil);
		return nil;
	end
	if self.unsorted[rrs] then table.sort (rrs, comp_mx); self.unsorted[rrs] = nil; end
	return rrs;
end


function resolver:purge(soft)    -- - - - - - - - - - - - - - - - - - -  purge
	if soft == 'soft' then
		self.time = socket.gettime();
		for class,types in pairs(self.cache or {}) do
			for type,names in pairs(types) do
				for name,rrs in pairs(names) do
					prune(rrs, self.time, 'soft')
				end
			end
		end
	else self.cache = setmetatable({}, cache_metatable); end
end


function resolver:query(qname, qtype, qclass)    -- - - - - - - - - - -- query
	qname, qtype, qclass = standardize(qname, qtype, qclass)

	local co = coroutine.running();
	local q = get(self.wanted, qclass, qtype, qname);
	if co and q then
		-- We are already waiting for a reply to an identical query.
		set(self.wanted, qclass, qtype, qname, co, true);
		return true;
	end

	if not self.server then self:adddefaultnameservers(); end

	local question = encodeQuestion(qname, qtype, qclass);
	local peek = self:peek (qname, qtype, qclass);
	if peek then return peek; end

	local header, id = encodeHeader();
	--print ('query  id', id, qclass, qtype, qname)
	local o = {
		packet = header..question,
		server = self.best_server,
		delay  = 1,
		retry  = socket.gettime() + self.delays[1]
	};

	-- remember the query
	self.active[id] = self.active[id] or {};
	self.active[id][question] = o;

	local conn, err = self:getsocket(o.server)
	if not conn then
		return nil, err;
	end
	conn:send (o.packet)

	-- remember which coroutine wants the answer
	if co then
		set(self.wanted, qclass, qtype, qname, co, true);
	end
	
	if timer and self.timeout then
		local num_servers = #self.server;
		local i = 1;
		timer.add_task(self.timeout, function ()
			if get(self.wanted, qclass, qtype, qname, co) then
				if i < num_servers then
					i = i + 1;
					self:servfail(conn);
					o.server = self.best_server;
					conn, err = self:getsocket(o.server);
					if conn then
						conn:send(o.packet);
						return self.timeout;
					end
				end
				-- Tried everything, failed
				self:cancel(qclass, qtype, qname);
			end
		end)
	end
	return true;
end

function resolver:servfail(sock, err)
	-- Resend all queries for this server

	local num = self.socketset[sock]

	-- Socket is dead now
	sock = self:voidsocket(sock);

	-- Find all requests to the down server, and retry on the next server
	self.time = socket.gettime();
	for id,queries in pairs(self.active) do
		for question,o in pairs(queries) do
			if o.server == num then -- This request was to the broken server
				o.server = o.server + 1 -- Use next server
				if o.server > #self.server then
					o.server = 1;
				end

				o.retries = (o.retries or 0) + 1;
				if o.retries >= #self.server then
					--print('timeout');
					queries[question] = nil;
				else
					sock, err = self:getsocket(o.server);
					if sock then sock:send(o.packet); end
				end
			end
		end
		if next(queries) == nil then
			self.active[id] = nil;
		end
	end

	if num == self.best_server then
		self.best_server = self.best_server + 1;
		if self.best_server > #self.server then
			-- Exhausted all servers, try first again
			self.best_server = 1;
		end
	end
	return sock, err;
end

function resolver:settimeout(seconds)
	self.timeout = seconds;
end

function resolver:receive(rset)    -- - - - - - - - - - - - - - - - -  receive
	--print('receive');  print(self.socket);
	self.time = socket.gettime();
	rset = rset or self.socket;

	local response;
	for _, sock in pairs(rset) do

		if self.socketset[sock] then
			local packet = sock:receive();
			if packet then
				response = self:decode(packet);
				if response and self.active[response.header.id]
					and self.active[response.header.id][response.question.raw] then
					--print('received response');
					--self.print(response);

					for _, rr in pairs(response.answer) do
						if rr.name:sub(-#response.question[1].name, -1) == response.question[1].name then
							self:remember(rr, response.question[1].type)
						end
					end

					-- retire the query
					local queries = self.active[response.header.id];
					queries[response.question.raw] = nil;
					
					if not next(queries) then self.active[response.header.id] = nil; end
					if not next(self.active) then self:closeall(); end

					-- was the query on the wanted list?
					local q = response.question[1];
					local cos = get(self.wanted, q.class, q.type, q.name);
					if cos then
						for co in pairs(cos) do
							if coroutine.status(co) == "suspended" then coroutine.resume(co); end
						end
						set(self.wanted, q.class, q.type, q.name, nil);
					end
				end
				
			end
		end
	end

	return response;
end


function resolver:feed(sock, packet, force)
	--print('receive'); print(self.socket);
	self.time = socket.gettime();

	local response = self:decode(packet, force);
	if response and self.active[response.header.id]
		and self.active[response.header.id][response.question.raw] then
		--print('received response');
		--self.print(response);

		for _, rr in pairs(response.answer) do
			self:remember(rr, rr.type);
		end

		for _, rr in pairs(response.additional) do
			self:remember(rr, rr.type);
		end

		-- retire the query
		local queries = self.active[response.header.id];
		queries[response.question.raw] = nil;
		if not next(queries) then self.active[response.header.id] = nil; end
		if not next(self.active) then self:closeall(); end

		-- was the query on the wanted list?
		local q = response.question[1];
		if q then
			local cos = get(self.wanted, q.class, q.type, q.name);
			if cos then
				for co in pairs(cos) do
					if coroutine.status(co) == "suspended" then coroutine.resume(co); end
				end
				set(self.wanted, q.class, q.type, q.name, nil);
			end
		end
	end

	return response;
end

function resolver:cancel(qclass, qtype, qname)
	local cos = get(self.wanted, qclass, qtype, qname);
	if cos then
		for co in pairs(cos) do
			if coroutine.status(co) == "suspended" then coroutine.resume(co); end
		end
		set(self.wanted, qclass, qtype, qname, nil);
	end
end

function resolver:pulse()    -- - - - - - - - - - - - - - - - - - - - -  pulse
	--print(':pulse');
	while self:receive() do end
	if not next(self.active) then return nil; end

	self.time = socket.gettime();
	for id,queries in pairs(self.active) do
		for question,o in pairs(queries) do
			if self.time >= o.retry then

				o.server = o.server + 1;
				if o.server > #self.server then
					o.server = 1;
					o.delay = o.delay + 1;
				end

				if o.delay > #self.delays then
					--print('timeout');
					queries[question] = nil;
					if not next(queries) then self.active[id] = nil; end
					if not next(self.active) then return nil; end
				else
					--print('retry', o.server, o.delay);
					local _a = self.socket[o.server];
					if _a then _a:send(o.packet); end
					o.retry = self.time + self.delays[o.delay];
				end
			end
		end
	end

	if next(self.active) then return true; end
	return nil;
end


function resolver:lookup(qname, qtype, qclass)    -- - - - - - - - - -  lookup
	self:query (qname, qtype, qclass)
	while self:pulse() do
		local recvt = {}
		for i, s in ipairs(self.socket) do
			recvt[i] = s
		end
		socket.select(recvt, nil, 4)
	end
	--print(self.cache);
	return self:peek(qname, qtype, qclass);
end

function resolver:lookupex(handler, qname, qtype, qclass)    -- - - - - - - - - -  lookup
	return self:peek(qname, qtype, qclass) or self:query(qname, qtype, qclass);
end

function resolver:tohostname(ip)
	return dns.lookup(ip:gsub("(%d+)%.(%d+)%.(%d+)%.(%d+)", "%4.%3.%2.%1.in-addr.arpa."), "PTR");
end

--print ---------------------------------------------------------------- print


local hints = {    -- - - - - - - - - - - - - - - - - - - - - - - - - - - hints
	qr = { [0]='query', 'response' },
	opcode = { [0]='query', 'inverse query', 'server status request' },
	aa = { [0]='non-authoritative', 'authoritative' },
	tc = { [0]='complete', 'truncated' },
	rd = { [0]='recursion not desired', 'recursion desired' },
	ra = { [0]='recursion not available', 'recursion available' },
	z  = { [0]='(reserved)' },
	rcode = { [0]='no error', 'format error', 'server failure', 'name error', 'not implemented' },

	type = dns.type,
	class = dns.class
};


local function hint(p, s)    -- - - - - - - - - - - - - - - - - - - - - - hint
	return (hints[s] and hints[s][p[s]]) or '';
end


function resolver.print(response)    -- - - - - - - - - - - - - resolver.print
	for _, s in pairs { 'id', 'qr', 'opcode', 'aa', 'tc', 'rd', 'ra', 'z',
						'rcode', 'qdcount', 'ancount', 'nscount', 'arcount' } do
		print( string.format('%-30s', 'header.'..s), response.header[s], hint(response.header, s) );
	end

	for i,question in ipairs(response.question) do
		print(string.format ('question[%i].name         ', i), question.name);
		print(string.format ('question[%i].type         ', i), question.type);
		print(string.format ('question[%i].class        ', i), question.class);
	end

	local common = { name=1, type=1, class=1, ttl=1, rdlength=1, rdata=1 };
	local tmp;
	for _, s in pairs({'answer', 'authority', 'additional'}) do
		for i,rr in pairs(response[s]) do
			for _, t in pairs({ 'name', 'type', 'class', 'ttl', 'rdlength' }) do
				tmp = string.format('%s[%i].%s', s, i, t);
				print(string.format('%-30s', tmp), rr[t], hint(rr, t));
			end
			for j,t in pairs(rr) do
				if not common[j] then
					tmp = string.format('%s[%i].%s', s, i, j);
					print(string.format('%-30s  %s', tostring(tmp), tostring(t)));
				end
			end
		end
	end
end


-- module api ------------------------------------------------------ module api


function dns.resolver ()    -- - - - - - - - - - - - - - - - - - - - - resolver
	local r = { active = {}, cache = {}, unsorted = {}, wanted = {}, best_server = 1 };
	setmetatable (r, resolver);
	setmetatable (r.cache, cache_metatable);
	setmetatable (r.unsorted, { __mode = 'kv' });
	return r;
end

local _resolver = dns.resolver();
dns._resolver = _resolver;

function dns.lookup(...)    -- - - - - - - - - - - - - - - - - - - - -  lookup
	return _resolver:lookup(...);
end

function dns.tohostname(...)
	return _resolver:tohostname(...);
end

function dns.purge(...)    -- - - - - - - - - - - - - - - - - - - - - -  purge
	return _resolver:purge(...);
end

function dns.peek(...)    -- - - - - - - - - - - - - - - - - - - - - - -  peek
	return _resolver:peek(...);
end

function dns.query(...)    -- - - - - - - - - - - - - - - - - - - - - -  query
	return _resolver:query(...);
end

function dns.feed(...)    -- - - - - - - - - - - - - - - - - - - - - - -  feed
	return _resolver:feed(...);
end

function dns.cancel(...)  -- - - - - - - - - - - - - - - - - - - - - -  cancel
	return _resolver:cancel(...);
end

function dns.settimeout(...)
	return _resolver:settimeout(...);
end

function dns.cache()
	return _resolver.cache;
end

function dns.socket_wrapper_set(...)    -- - - - - - - - -  socket_wrapper_set
	return _resolver:socket_wrapper_set(...);
end

return dns;
 end)
package.preload['net.adns'] = (function (...)
					local _ENV = _ENV;
					local function module(name, ...)
						local t = package.loaded[name] or _ENV[name] or { _NAME = name };
						package.loaded[name] = t;
						for i = 1, select("#", ...) do
							(select(i, ...))(t);
						end
						_ENV = t;
						_M = t;
						return t;
					end
				-- Prosody IM
-- Copyright (C) 2008-2010 Matthew Wild
-- Copyright (C) 2008-2010 Waqas Hussain
--
-- This project is MIT/X11 licensed. Please see the
-- COPYING file in the source package for more information.
--

local server = require "net.server";
local new_resolver = require "net.dns".resolver;

local log = require "util.logger".init("adns");

local coroutine, tostring, pcall = coroutine, tostring, pcall;
local setmetatable = setmetatable;

local function dummy_send(sock, data, i, j) return (j-i)+1; end

local _ENV = nil;

local async_resolver_methods = {};
local async_resolver_mt = { __index = async_resolver_methods };

local query_methods = {};
local query_mt = { __index = query_methods };

local function new_async_socket(sock, resolver)
	local peername = "<unknown>";
	local listener = {};
	local handler = {};
	local err;
	function listener.onincoming(conn, data)
		if data then
			resolver:feed(handler, data);
		end
	end
	function listener.ondisconnect(conn, err)
		if err then
			log("warn", "DNS socket for %s disconnected: %s", peername, err);
			local servers = resolver.server;
			if resolver.socketset[conn] == resolver.best_server and resolver.best_server == #servers then
				log("error", "Exhausted all %d configured DNS servers, next lookup will try %s again", #servers, servers[1]);
			end

			resolver:servfail(conn); -- Let the magic commence
		end
	end
	handler, err = server.wrapclient(sock, "dns", 53, listener);
	if not handler then
		return nil, err;
	end

	handler.settimeout = function () end
	handler.setsockname = function (_, ...) return sock:setsockname(...); end
	handler.setpeername = function (_, ...) peername = (...); local ret, err = sock:setpeername(...); _:set_send(dummy_send); return ret, err; end
	handler.connect = function (_, ...) return sock:connect(...) end
	--handler.send = function (_, data) _:write(data);  return _.sendbuffer and _.sendbuffer(); end
	handler.send = function (_, data)
		log("debug", "Sending DNS query to %s", peername);
		return sock:send(data);
	end
	return handler;
end

function async_resolver_methods:lookup(handler, qname, qtype, qclass)
	local resolver = self._resolver;
	return coroutine.wrap(function (peek)
				if peek then
					log("debug", "Records for %s already cached, using those...", qname);
					handler(peek);
					return;
				end
				log("debug", "Records for %s not in cache, sending query (%s)...", qname, tostring(coroutine.running()));
				local ok, err = resolver:query(qname, qtype, qclass);
				if ok then
					coroutine.yield(setmetatable({ resolver, qclass or "IN", qtype or "A", qname, coroutine.running()}, query_mt)); -- Wait for reply
					log("debug", "Reply for %s (%s)", qname, tostring(coroutine.running()));
				end
				if ok then
					ok, err = pcall(handler, resolver:peek(qname, qtype, qclass));
				else
					log("error", "Error sending DNS query: %s", err);
					ok, err = pcall(handler, nil, err);
				end
				if not ok then
					log("error", "Error in DNS response handler: %s", tostring(err));
				end
			end)(resolver:peek(qname, qtype, qclass));
end

function query_methods:cancel(call_handler, reason)
	log("warn", "Cancelling DNS lookup for %s", tostring(self[4]));
	self[1].cancel(self[2], self[3], self[4], self[5], call_handler);
end

local function new_async_resolver()
	local resolver = new_resolver();
	resolver:socket_wrapper_set(new_async_socket);
	return setmetatable({ _resolver = resolver}, async_resolver_mt);
end

return {
	lookup = function (...)
		return new_async_resolver():lookup(...);
	end;
	resolver = new_async_resolver;
	new_async_socket = new_async_socket;
};
 end)
package.preload['net.server'] = (function (...)
					local _ENV = _ENV;
					local function module(name, ...)
						local t = package.loaded[name] or _ENV[name] or { _NAME = name };
						package.loaded[name] = t;
						for i = 1, select("#", ...) do
							(select(i, ...))(t);
						end
						_ENV = t;
						_M = t;
						return t;
					end
				--
-- server.lua by blastbeat of the luadch project
-- Re-used here under the MIT/X Consortium License
--
-- Modifications (C) 2008-2010 Matthew Wild, Waqas Hussain
--

-- // wrapping luadch stuff // --

local use = function( what )
	return _G[ what ]
end

local log, table_concat = require ("util.logger").init("socket"), table.concat;
local out_put = function (...) return log("debug", table_concat{...}); end
local out_error = function (...) return log("warn", table_concat{...}); end

----------------------------------// DECLARATION //--

--// constants //--

local STAT_UNIT = 1 -- byte

--// lua functions //--

local type = use "type"
local pairs = use "pairs"
local ipairs = use "ipairs"
local tonumber = use "tonumber"
local tostring = use "tostring"

--// lua libs //--

local table = use "table"
local string = use "string"
local coroutine = use "coroutine"

--// lua lib methods //--

local math_min = math.min
local math_huge = math.huge
local table_concat = table.concat
local string_sub = string.sub
local coroutine_wrap = coroutine.wrap
local coroutine_yield = coroutine.yield

--// extern libs //--

local has_luasec, luasec = pcall ( require , "ssl" )
local luasocket = use "socket" or require "socket"
local luasocket_gettime = luasocket.gettime
local getaddrinfo = luasocket.dns.getaddrinfo

--// extern lib methods //--

local ssl_wrap = ( has_luasec and luasec.wrap )
local socket_bind = luasocket.bind
local socket_sleep = luasocket.sleep
local socket_select = luasocket.select

--// functions //--

local id
local loop
local stats
local idfalse
local closeall
local addsocket
local addserver
local addtimer
local getserver
local wrapserver
local getsettings
local closesocket
local removesocket
local removeserver
local wrapconnection
local changesettings

--// tables //--

local _server
local _readlist
local _timerlist
local _sendlist
local _socketlist
local _closelist
local _readtimes
local _writetimes
local _fullservers

--// simple data types //--

local _
local _readlistlen
local _sendlistlen
local _timerlistlen

local _sendtraffic
local _readtraffic

local _selecttimeout
local _sleeptime
local _tcpbacklog
local _accepretry

local _starttime
local _currenttime

local _maxsendlen
local _maxreadlen

local _checkinterval
local _sendtimeout
local _readtimeout

local _timer

local _maxselectlen
local _maxfd

local _maxsslhandshake

----------------------------------// DEFINITION //--

_server = { } -- key = port, value = table; list of listening servers
_readlist = { } -- array with sockets to read from
_sendlist = { } -- arrary with sockets to write to
_timerlist = { } -- array of timer functions
_socketlist = { } -- key = socket, value = wrapped socket (handlers)
_readtimes = { } -- key = handler, value = timestamp of last data reading
_writetimes = { } -- key = handler, value = timestamp of last data writing/sending
_closelist = { } -- handlers to close
_fullservers = { } -- servers in a paused state while there are too many clients

_readlistlen = 0 -- length of readlist
_sendlistlen = 0 -- length of sendlist
_timerlistlen = 0 -- lenght of timerlist

_sendtraffic = 0 -- some stats
_readtraffic = 0

_selecttimeout = 1 -- timeout of socket.select
_sleeptime = 0 -- time to wait at the end of every loop
_tcpbacklog = 128 -- some kind of hint to the OS
_accepretry = 10 -- seconds to wait until the next attempt of a full server to accept

_maxsendlen = 51000 * 1024 -- max len of send buffer
_maxreadlen = 25000 * 1024 -- max len of read buffer

_checkinterval = 30 -- interval in secs to check idle clients
_sendtimeout = 60000 -- allowed send idle time in secs
_readtimeout = 6 * 60 * 60 -- allowed read idle time in secs

local is_windows = package.config:sub(1,1) == "\\" -- check the directory separator, to detemine whether this is Windows
_maxfd = (is_windows and math.huge) or luasocket._SETSIZE or 1024 -- max fd number, limit to 1024 by default to prevent glibc buffer overflow, but not on Windows
_maxselectlen = luasocket._SETSIZE or 1024 -- But this still applies on Windows

_maxsslhandshake = 30 -- max handshake round-trips

----------------------------------// PRIVATE //--

wrapserver = function( listeners, socket, ip, serverport, pattern, sslctx ) -- this function wraps a server -- FIXME Make sure FD < _maxfd

	if socket:getfd() >= _maxfd then
		out_error("server.lua: Disallowed FD number: "..socket:getfd())
		socket:close()
		return nil, "fd-too-large"
	end

	local connections = 0

	local dispatch, disconnect = listeners.onconnect, listeners.ondisconnect

	local accept = socket.accept

	--// public methods of the object //--

	local handler = { }

	handler.shutdown = function( ) end

	handler.ssl = function( )
		return sslctx ~= nil
	end
	handler.sslctx = function( )
		return sslctx
	end
	handler.remove = function( )
		connections = connections - 1
		if handler then
			handler.resume( )
		end
	end
	handler.close = function()
		socket:close( )
		_sendlistlen = removesocket( _sendlist, socket, _sendlistlen )
		_readlistlen = removesocket( _readlist, socket, _readlistlen )
		_server[ip..":"..serverport] = nil;
		_socketlist[ socket ] = nil
		handler = nil
		socket = nil
		--mem_free( )
		out_put "server.lua: closed server handler and removed sockets from list"
	end
	handler.pause = function( hard )
		if not handler.paused then
			_readlistlen = removesocket( _readlist, socket, _readlistlen )
			if hard then
				_socketlist[ socket ] = nil
				socket:close( )
				socket = nil;
			end
			handler.paused = true;
			out_put("server.lua: server [", ip, "]:", serverport, " paused")
		end
	end
	handler.resume = function( )
		if handler.paused then
			if not socket then
				socket = socket_bind( ip, serverport, _tcpbacklog );
				socket:settimeout( 0 )
			end
			_readlistlen = addsocket(_readlist, socket, _readlistlen)
			_socketlist[ socket ] = handler
			_fullservers[ handler ] = nil
			handler.paused = false;
			out_put("server.lua: server [", ip, "]:", serverport, " resumed")
		end
	end
	handler.ip = function( )
		return ip
	end
	handler.serverport = function( )
		return serverport
	end
	handler.socket = function( )
		return socket
	end
	handler.readbuffer = function( )
		if _readlistlen >= _maxselectlen or _sendlistlen >= _maxselectlen then
			handler.pause( )
			_fullservers[ handler ] = _currenttime
			out_put( "server.lua: refused new client connection: server full" )
			return false
		end
		local client, err = accept( socket )	-- try to accept
		if client then
			local ip, clientport = client:getpeername( )
			local handler, client, err = wrapconnection( handler, listeners, client, ip, serverport, clientport, pattern, sslctx ) -- wrap new client socket
			if err then -- error while wrapping ssl socket
				return false
			end
			connections = connections + 1
			out_put( "server.lua: accepted new client connection from ", tostring(ip), ":", tostring(clientport), " to ", tostring(serverport))
			if dispatch and not sslctx then -- SSL connections will notify onconnect when handshake completes
				return dispatch( handler );
			end
			return;
		elseif err then -- maybe timeout or something else
			out_put( "server.lua: error with new client connection: ", tostring(err) )
			handler.pause( )
			_fullservers[ handler ] = _currenttime
			return false
		end
	end
	return handler
end

wrapconnection = function( server, listeners, socket, ip, serverport, clientport, pattern, sslctx ) -- this function wraps a client to a handler object

	if socket:getfd() >= _maxfd then
		out_error("server.lua: Disallowed FD number: "..socket:getfd()) -- PROTIP: Switch to libevent
		socket:close( ) -- Should we send some kind of error here?
		if server then
			_fullservers[ server ] = _currenttime
			server.pause( )
		end
		return nil, nil, "fd-too-large"
	end
	socket:settimeout( 0 )

	--// local import of socket methods //--

	local send
	local receive
	local shutdown

	--// private closures of the object //--

	local ssl

	local dispatch = listeners.onincoming
	local status = listeners.onstatus
	local disconnect = listeners.ondisconnect
	local drain = listeners.ondrain
	local onreadtimeout = listeners.onreadtimeout;
	local detach = listeners.ondetach

	local bufferqueue = { } -- buffer array
	local bufferqueuelen = 0	-- end of buffer array

	local toclose
	local fatalerror
	local needtls

	local bufferlen = 0

	local noread = false
	local nosend = false

	local sendtraffic, readtraffic = 0, 0

	local maxsendlen = _maxsendlen
	local maxreadlen = _maxreadlen

	--// public methods of the object //--

	local handler = bufferqueue -- saves a table ^_^

	handler.dispatch = function( )
		return dispatch
	end
	handler.disconnect = function( )
		return disconnect
	end
	handler.onreadtimeout = onreadtimeout;

	handler.setlistener = function( self, listeners )
		if detach then
			detach(self) -- Notify listener that it is no longer responsible for this connection
		end
		dispatch = listeners.onincoming
		disconnect = listeners.ondisconnect
		status = listeners.onstatus
		drain = listeners.ondrain
		handler.onreadtimeout = listeners.onreadtimeout
		detach = listeners.ondetach
	end
	handler.getstats = function( )
		return readtraffic, sendtraffic
	end
	handler.ssl = function( )
		return ssl
	end
	handler.sslctx = function ( )
		return sslctx
	end
	handler.send = function( _, data, i, j )
		return send( socket, data, i, j )
	end
	handler.receive = function( pattern, prefix )
		return receive( socket, pattern, prefix )
	end
	handler.shutdown = function( pattern )
		return shutdown( socket, pattern )
	end
	handler.setoption = function (self, option, value)
		if socket.setoption then
			return socket:setoption(option, value);
		end
		return false, "setoption not implemented";
	end
	handler.force_close = function ( self, err )
		if bufferqueuelen ~= 0 then
			out_put("server.lua: discarding unwritten data for ", tostring(ip), ":", tostring(clientport))
			bufferqueuelen = 0;
		end
		return self:close(err);
	end
	handler.close = function( self, err )
		if not handler then return true; end
		_readlistlen = removesocket( _readlist, socket, _readlistlen )
		_readtimes[ handler ] = nil
		if bufferqueuelen ~= 0 then
			handler.sendbuffer() -- Try now to send any outstanding data
			if bufferqueuelen ~= 0 then -- Still not empty, so we'll try again later
				if handler then
					handler.write = nil -- ... but no further writing allowed
				end
				toclose = true
				return false
			end
		end
		if socket then
			_ = shutdown and shutdown( socket )
			socket:close( )
			_sendlistlen = removesocket( _sendlist, socket, _sendlistlen )
			_socketlist[ socket ] = nil
			socket = nil
		else
			out_put "server.lua: socket already closed"
		end
		if handler then
			_writetimes[ handler ] = nil
			_closelist[ handler ] = nil
			local _handler = handler;
			handler = nil
			if disconnect then
				disconnect(_handler, err or false);
				disconnect = nil
			end
		end
		if server then
			server.remove( )
		end
		out_put "server.lua: closed client handler and removed socket from list"
		return true
	end
	handler.server = function ( )
		return server
	end
	handler.ip = function( )
		return ip
	end
	handler.serverport = function( )
		return serverport
	end
	handler.clientport = function( )
		return clientport
	end
	handler.port = handler.clientport -- COMPAT server_event
	local write = function( self, data )
		if not handler then return false end
		bufferlen = bufferlen + #data
		if bufferlen > maxsendlen then
			_closelist[ handler ] = "send buffer exceeded"	 -- cannot close the client at the moment, have to wait to the end of the cycle
			handler.write = idfalse -- dont write anymore
			return false
		elseif socket and not _sendlist[ socket ] then
			_sendlistlen = addsocket(_sendlist, socket, _sendlistlen)
		end
		bufferqueuelen = bufferqueuelen + 1
		bufferqueue[ bufferqueuelen ] = data
		if handler then
			_writetimes[ handler ] = _writetimes[ handler ] or _currenttime
		end
		return true
	end
	handler.write = write
	handler.bufferqueue = function( self )
		return bufferqueue
	end
	handler.socket = function( self )
		return socket
	end
	handler.set_mode = function( self, new )
		pattern = new or pattern
		return pattern
	end
	handler.set_send = function ( self, newsend )
		send = newsend or send
		return send
	end
	handler.bufferlen = function( self, readlen, sendlen )
		maxsendlen = sendlen or maxsendlen
		maxreadlen = readlen or maxreadlen
		return bufferlen, maxreadlen, maxsendlen
	end
	--TODO: Deprecate
	handler.lock_read = function (self, switch)
		if switch == true then
			local tmp = _readlistlen
			_readlistlen = removesocket( _readlist, socket, _readlistlen )
			_readtimes[ handler ] = nil
			if _readlistlen ~= tmp then
				noread = true
			end
		elseif switch == false then
			if noread then
				noread = false
				_readlistlen = addsocket(_readlist, socket, _readlistlen)
				_readtimes[ handler ] = _currenttime
			end
		end
		return noread
	end
	handler.pause = function (self)
		return self:lock_read(true);
	end
	handler.resume = function (self)
		return self:lock_read(false);
	end
	handler.lock = function( self, switch )
		handler.lock_read (switch)
		if switch == true then
			handler.write = idfalse
			local tmp = _sendlistlen
			_sendlistlen = removesocket( _sendlist, socket, _sendlistlen )
			_writetimes[ handler ] = nil
			if _sendlistlen ~= tmp then
				nosend = true
			end
		elseif switch == false then
			handler.write = write
			if nosend then
				nosend = false
				write( "" )
			end
		end
		return noread, nosend
	end
	local _readbuffer = function( ) -- this function reads data
		local buffer, err, part = receive( socket, pattern )	-- receive buffer with "pattern"
		if not err or (err == "wantread" or err == "timeout") then -- received something
			local buffer = buffer or part or ""
			local len = #buffer
			if len > maxreadlen then
				handler:close( "receive buffer exceeded" )
				return false
			end
			local count = len * STAT_UNIT
			readtraffic = readtraffic + count
			_readtraffic = _readtraffic + count
			_readtimes[ handler ] = _currenttime
			--out_put( "server.lua: read data '", buffer:gsub("[^%w%p ]", "."), "', error: ", err )
			return dispatch( handler, buffer, err )
		else	-- connections was closed or fatal error
			out_put( "server.lua: client ", tostring(ip), ":", tostring(clientport), " read error: ", tostring(err) )
			fatalerror = true
			_ = handler and handler:force_close( err )
			return false
		end
	end
	local _sendbuffer = function( ) -- this function sends data
		local succ, err, byte, buffer, count;
		if socket then
			buffer = table_concat( bufferqueue, "", 1, bufferqueuelen )
			succ, err, byte = send( socket, buffer, 1, bufferlen )
			count = ( succ or byte or 0 ) * STAT_UNIT
			sendtraffic = sendtraffic + count
			_sendtraffic = _sendtraffic + count
			for i = bufferqueuelen,1,-1 do
				bufferqueue[ i ] = nil
			end
			--out_put( "server.lua: sended '", buffer, "', bytes: ", tostring(succ), ", error: ", tostring(err), ", part: ", tostring(byte), ", to: ", tostring(ip), ":", tostring(clientport) )
		else
			succ, err, count = false, "unexpected close", 0;
		end
		if succ then	-- sending succesful
			bufferqueuelen = 0
			bufferlen = 0
			_sendlistlen = removesocket( _sendlist, socket, _sendlistlen ) -- delete socket from writelist
			_writetimes[ handler ] = nil
			if drain then
				drain(handler)
			end
			_ = needtls and handler:starttls(nil)
			_ = toclose and handler:force_close( )
			return true
		elseif byte and ( err == "timeout" or err == "wantwrite" ) then -- want write
			buffer = string_sub( buffer, byte + 1, bufferlen ) -- new buffer
			bufferqueue[ 1 ] = buffer	 -- insert new buffer in queue
			bufferqueuelen = 1
			bufferlen = bufferlen - byte
			_writetimes[ handler ] = _currenttime
			return true
		else	-- connection was closed during sending or fatal error
			out_put( "server.lua: client ", tostring(ip), ":", tostring(clientport), " write error: ", tostring(err) )
			fatalerror = true
			_ = handler and handler:force_close( err )
			return false
		end
	end

	-- Set the sslctx
	local handshake;
	function handler.set_sslctx(self, new_sslctx)
		sslctx = new_sslctx;
		local read, wrote
		handshake = coroutine_wrap( function( client ) -- create handshake coroutine
				local err
				for _ = 1, _maxsslhandshake do
					_sendlistlen = ( wrote and removesocket( _sendlist, client, _sendlistlen ) ) or _sendlistlen
					_readlistlen = ( read and removesocket( _readlist, client, _readlistlen ) ) or _readlistlen
					read, wrote = nil, nil
					_, err = client:dohandshake( )
					if not err then
						out_put( "server.lua: ssl handshake done" )
						handler.readbuffer = _readbuffer	-- when handshake is done, replace the handshake function with regular functions
						handler.sendbuffer = _sendbuffer
						_ = status and status( handler, "ssl-handshake-complete" )
						if self.autostart_ssl and listeners.onconnect then
							listeners.onconnect(self);
							if bufferqueuelen ~= 0 then
								_sendlistlen = addsocket(_sendlist, client, _sendlistlen)
							end
						end
						_readlistlen = addsocket(_readlist, client, _readlistlen)
						return true
					else
						if err == "wantwrite" then
							_sendlistlen = addsocket(_sendlist, client, _sendlistlen)
							wrote = true
						elseif err == "wantread" then
							_readlistlen = addsocket(_readlist, client, _readlistlen)
							read = true
						else
							break;
						end
						err = nil;
						coroutine_yield( ) -- handshake not finished
					end
				end
				err = "ssl handshake error: " .. ( err or "handshake too long" );
				out_put( "server.lua: ", err );
				_ = handler and handler:force_close(err)
				return false, err -- handshake failed
			end
		)
	end
	if has_luasec then
		handler.starttls = function( self, _sslctx)
			if _sslctx then
				handler:set_sslctx(_sslctx);
			end
			if bufferqueuelen > 0 then
				out_put "server.lua: we need to do tls, but delaying until send buffer empty"
				needtls = true
				return
			end
			out_put( "server.lua: attempting to start tls on " .. tostring( socket ) )
			local oldsocket, err = socket
			socket, err = ssl_wrap( socket, sslctx )	-- wrap socket
			if not socket then
				out_put( "server.lua: error while starting tls on client: ", tostring(err or "unknown error") )
				return nil, err -- fatal error
			end

			socket:settimeout( 0 )

			-- add the new socket to our system
			send = socket.send
			receive = socket.receive
			shutdown = id
			_socketlist[ socket ] = handler
			_readlistlen = addsocket(_readlist, socket, _readlistlen)

			-- remove traces of the old socket
			_readlistlen = removesocket( _readlist, oldsocket, _readlistlen )
			_sendlistlen = removesocket( _sendlist, oldsocket, _sendlistlen )
			_socketlist[ oldsocket ] = nil

			handler.starttls = nil
			needtls = nil

			-- Secure now (if handshake fails connection will close)
			ssl = true

			handler.readbuffer = handshake
			handler.sendbuffer = handshake
			return handshake( socket ) -- do handshake
		end
	end

	handler.readbuffer = _readbuffer
	handler.sendbuffer = _sendbuffer
	send = socket.send
	receive = socket.receive
	shutdown = ( ssl and id ) or socket.shutdown

	_socketlist[ socket ] = handler
	_readlistlen = addsocket(_readlist, socket, _readlistlen)

	if sslctx and has_luasec then
		out_put "server.lua: auto-starting ssl negotiation..."
		handler.autostart_ssl = true;
		local ok, err = handler:starttls(sslctx);
		if ok == false then
			return nil, nil, err
		end
	end

	return handler, socket
end

id = function( )
end

idfalse = function( )
	return false
end

addsocket = function( list, socket, len )
	if not list[ socket ] then
		len = len + 1
		list[ len ] = socket
		list[ socket ] = len
	end
	return len;
end

removesocket = function( list, socket, len )	-- this function removes sockets from a list ( copied from copas )
	local pos = list[ socket ]
	if pos then
		list[ socket ] = nil
		local last = list[ len ]
		list[ len ] = nil
		if last ~= socket then
			list[ last ] = pos
			list[ pos ] = last
		end
		return len - 1
	end
	return len
end

closesocket = function( socket )
	_sendlistlen = removesocket( _sendlist, socket, _sendlistlen )
	_readlistlen = removesocket( _readlist, socket, _readlistlen )
	_socketlist[ socket ] = nil
	socket:close( )
	--mem_free( )
end

local function link(sender, receiver, buffersize)
	local sender_locked;
	local _sendbuffer = receiver.sendbuffer;
	function receiver.sendbuffer()
		_sendbuffer();
		if sender_locked and receiver.bufferlen() < buffersize then
			sender:lock_read(false); -- Unlock now
			sender_locked = nil;
		end
	end

	local _readbuffer = sender.readbuffer;
	function sender.readbuffer()
		_readbuffer();
		if not sender_locked and receiver.bufferlen() >= buffersize then
			sender_locked = true;
			sender:lock_read(true);
		end
	end
	sender:set_mode("*a");
end

----------------------------------// PUBLIC //--

addserver = function( addr, port, listeners, pattern, sslctx ) -- this function provides a way for other scripts to reg a server
	addr = addr or "*"
	local err
	if type( listeners ) ~= "table" then
		err = "invalid listener table"
	elseif type ( addr ) ~= "string" then
		err = "invalid address"
	elseif type( port ) ~= "number" or not ( port >= 0 and port <= 65535 ) then
		err = "invalid port"
	elseif _server[ addr..":"..port ] then
		err = "listeners on '[" .. addr .. "]:" .. port .. "' already exist"
	elseif sslctx and not has_luasec then
		err = "luasec not found"
	end
	if err then
		out_error( "server.lua, [", addr, "]:", port, ": ", err )
		return nil, err
	end
	local server, err = socket_bind( addr, port, _tcpbacklog )
	if err then
		out_error( "server.lua, [", addr, "]:", port, ": ", err )
		return nil, err
	end
	local handler, err = wrapserver( listeners, server, addr, port, pattern, sslctx ) -- wrap new server socket
	if not handler then
		server:close( )
		return nil, err
	end
	server:settimeout( 0 )
	_readlistlen = addsocket(_readlist, server, _readlistlen)
	_server[ addr..":"..port ] = handler
	_socketlist[ server ] = handler
	out_put( "server.lua: new "..(sslctx and "ssl " or "").."server listener on '[", addr, "]:", port, "'" )
	return handler
end

getserver = function ( addr, port )
	return _server[ addr..":"..port ];
end

removeserver = function( addr, port )
	local handler = _server[ addr..":"..port ]
	if not handler then
		return nil, "no server found on '[" .. addr .. "]:" .. tostring( port ) .. "'"
	end
	handler:close( )
	_server[ addr..":"..port ] = nil
	return true
end

closeall = function( )
	for _, handler in pairs( _socketlist ) do
		handler:close( )
		_socketlist[ _ ] = nil
	end
	_readlistlen = 0
	_sendlistlen = 0
	_timerlistlen = 0
	_server = { }
	_readlist = { }
	_sendlist = { }
	_timerlist = { }
	_socketlist = { }
	--mem_free( )
end

getsettings = function( )
	return {
		select_timeout = _selecttimeout;
		select_sleep_time = _sleeptime;
		tcp_backlog = _tcpbacklog;
		max_send_buffer_size = _maxsendlen;
		max_receive_buffer_size = _maxreadlen;
		select_idle_check_interval = _checkinterval;
		send_timeout = _sendtimeout;
		read_timeout = _readtimeout;
		max_connections = _maxselectlen;
		max_ssl_handshake_roundtrips = _maxsslhandshake;
		highest_allowed_fd = _maxfd;
		accept_retry_interval = _accepretry;
	}
end

changesettings = function( new )
	if type( new ) ~= "table" then
		return nil, "invalid settings table"
	end
	_selecttimeout = tonumber( new.select_timeout ) or _selecttimeout
	_sleeptime = tonumber( new.select_sleep_time ) or _sleeptime
	_maxsendlen = tonumber( new.max_send_buffer_size ) or _maxsendlen
	_maxreadlen = tonumber( new.max_receive_buffer_size ) or _maxreadlen
	_checkinterval = tonumber( new.select_idle_check_interval ) or _checkinterval
	_tcpbacklog = tonumber( new.tcp_backlog ) or _tcpbacklog
	_sendtimeout = tonumber( new.send_timeout ) or _sendtimeout
	_readtimeout = tonumber( new.read_timeout ) or _readtimeout
	_accepretry = tonumber( new.accept_retry_interval ) or _accepretry
	_maxselectlen = new.max_connections or _maxselectlen
	_maxsslhandshake = new.max_ssl_handshake_roundtrips or _maxsslhandshake
	_maxfd = new.highest_allowed_fd or _maxfd
	return true
end

addtimer = function( listener )
	if type( listener ) ~= "function" then
		return nil, "invalid listener function"
	end
	_timerlistlen = _timerlistlen + 1
	_timerlist[ _timerlistlen ] = listener
	return true
end

stats = function( )
	return _readtraffic, _sendtraffic, _readlistlen, _sendlistlen, _timerlistlen
end

local quitting;

local function setquitting(quit)
	quitting = not not quit;
end

loop = function(once) -- this is the main loop of the program
	if quitting then return "quitting"; end
	if once then quitting = "once"; end
	local next_timer_time = math_huge;
	repeat
		local read, write, err = socket_select( _readlist, _sendlist, math_min(_selecttimeout, next_timer_time) )
		for _, socket in ipairs( write ) do -- send data waiting in writequeues
			local handler = _socketlist[ socket ]
			if handler then
				handler.sendbuffer( )
			else
				closesocket( socket )
				out_put "server.lua: found no handler and closed socket (writelist)"	-- this should not happen
			end
		end
		for _, socket in ipairs( read ) do -- receive data
			local handler = _socketlist[ socket ]
			if handler then
				handler.readbuffer( )
			else
				closesocket( socket )
				out_put "server.lua: found no handler and closed socket (readlist)" -- this can happen
			end
		end
		for handler, err in pairs( _closelist ) do
			handler.disconnect( )( handler, err )
			handler:force_close()	 -- forced disconnect
			_closelist[ handler ] = nil;
		end
		_currenttime = luasocket_gettime( )

		-- Check for socket timeouts
		if _currenttime - _starttime > _checkinterval then
			_starttime = _currenttime
			for handler, timestamp in pairs( _writetimes ) do
				if _currenttime - timestamp > _sendtimeout then
					handler.disconnect( )( handler, "send timeout" )
					handler:force_close()	 -- forced disconnect
				end
			end
			for handler, timestamp in pairs( _readtimes ) do
				if _currenttime - timestamp > _readtimeout then
					if not(handler.onreadtimeout) or handler:onreadtimeout() ~= true then
						handler.disconnect( )( handler, "read timeout" )
						handler:close( )	-- forced disconnect?
					else
						_readtimes[ handler ] = _currenttime -- reset timer
					end
				end
			end
		end

		-- Fire timers
		if _currenttime - _timer >= math_min(next_timer_time, 1) then
			next_timer_time = math_huge;
			for i = 1, _timerlistlen do
				local t = _timerlist[ i ]( _currenttime ) -- fire timers
				if t then next_timer_time = math_min(next_timer_time, t); end
			end
			_timer = _currenttime
		else
			next_timer_time = next_timer_time - (_currenttime - _timer);
		end

		for server, paused_time in pairs( _fullservers ) do
			if _currenttime - paused_time > _accepretry then
				_fullservers[ server ] = nil;
				server.resume();
			end
		end

		-- wait some time (0 by default)
		socket_sleep( _sleeptime )
	until quitting;
	if once and quitting == "once" then quitting = nil; return; end
	closeall();
	return "quitting"
end

local function step()
	return loop(true);
end

local function get_backend()
	return "select";
end

--// EXPERIMENTAL //--

local wrapclient = function( socket, ip, serverport, listeners, pattern, sslctx )
	local handler, socket, err = wrapconnection( nil, listeners, socket, ip, serverport, "clientport", pattern, sslctx )
	if not handler then return nil, err end
	_socketlist[ socket ] = handler
	if not sslctx then
		_sendlistlen = addsocket(_sendlist, socket, _sendlistlen)
		if listeners.onconnect then
			-- When socket is writeable, call onconnect
			local _sendbuffer = handler.sendbuffer;
			handler.sendbuffer = function ()
				handler.sendbuffer = _sendbuffer;
				listeners.onconnect(handler);
				return _sendbuffer(); -- Send any queued outgoing data
			end
		end
	end
	return handler, socket
end

local addclient = function( address, port, listeners, pattern, sslctx, typ )
	local err
	if type( listeners ) ~= "table" then
		err = "invalid listener table"
	elseif type ( address ) ~= "string" then
		err = "invalid address"
	elseif type( port ) ~= "number" or not ( port >= 0 and port <= 65535 ) then
		err = "invalid port"
	elseif sslctx and not has_luasec then
		err = "luasec not found"
	end
	if not typ then
		local addrinfo, err = getaddrinfo(address)
		if not addrinfo then return nil, err end
		if addrinfo[1] and addrinfo[1].family == "inet6" then
			typ = "tcp6"
		else
			typ = "tcp"
		end
	end
	local create = luasocket[typ]
	if type( create ) ~= "function"  then
		err = "invalid socket type"
	end

	if err then
		out_error( "server.lua, addclient: ", err )
		return nil, err
	end

	local client, err = create( )
	if err then
		return nil, err
	end
	client:settimeout( 0 )
	local ok, err = client:connect( address, port )
	if ok or err == "timeout" then
		return wrapclient( client, address, port, listeners, pattern, sslctx )
	else
		return nil, err
	end
end

--// EXPERIMENTAL //--

----------------------------------// BEGIN //--

use "setmetatable" ( _socketlist, { __mode = "k" } )
use "setmetatable" ( _readtimes, { __mode = "k" } )
use "setmetatable" ( _writetimes, { __mode = "k" } )

_timer = luasocket_gettime( )
_starttime = luasocket_gettime( )

local function setlogger(new_logger)
	local old_logger = log;
	if new_logger then
		log = new_logger;
	end
	return old_logger;
end

----------------------------------// PUBLIC INTERFACE //--

return {
	_addtimer = addtimer,

	addclient = addclient,
	wrapclient = wrapclient,

	loop = loop,
	link = link,
	step = step,
	stats = stats,
	closeall = closeall,
	addserver = addserver,
	getserver = getserver,
	setlogger = setlogger,
	getsettings = getsettings,
	setquitting = setquitting,
	removeserver = removeserver,
	get_backend = get_backend,
	changesettings = changesettings,
}
 end)
package.preload['util.xmppstream'] = (function (...)
					local _ENV = _ENV;
					local function module(name, ...)
						local t = package.loaded[name] or _ENV[name] or { _NAME = name };
						package.loaded[name] = t;
						for i = 1, select("#", ...) do
							(select(i, ...))(t);
						end
						_ENV = t;
						_M = t;
						return t;
					end
				-- Prosody IM
-- Copyright (C) 2008-2010 Matthew Wild
-- Copyright (C) 2008-2010 Waqas Hussain
--
-- This project is MIT/X11 licensed. Please see the
-- COPYING file in the source package for more information.
--

local lxp = require "lxp";
local st = require "util.stanza";
local stanza_mt = st.stanza_mt;

local error = error;
local tostring = tostring;
local t_insert = table.insert;
local t_concat = table.concat;
local t_remove = table.remove;
local setmetatable = setmetatable;

-- COMPAT: w/LuaExpat 1.1.0
local lxp_supports_doctype = pcall(lxp.new, { StartDoctypeDecl = false });
local lxp_supports_xmldecl = pcall(lxp.new, { XmlDecl = false });
local lxp_supports_bytecount = not not lxp.new({}).getcurrentbytecount;

local default_stanza_size_limit = 1024*1024*10; -- 10MB

local _ENV = nil;

local new_parser = lxp.new;

local xml_namespace = {
	["http://www.w3.org/XML/1998/namespace\1lang"] = "xml:lang";
	["http://www.w3.org/XML/1998/namespace\1space"] = "xml:space";
	["http://www.w3.org/XML/1998/namespace\1base"] = "xml:base";
	["http://www.w3.org/XML/1998/namespace\1id"] = "xml:id";
};

local xmlns_streams = "http://etherx.jabber.org/streams";

local ns_separator = "\1";
local ns_pattern = "^([^"..ns_separator.."]*)"..ns_separator.."?(.*)$";

local function dummy_cb() end

local function new_sax_handlers(session, stream_callbacks, cb_handleprogress)
	local xml_handlers = {};

	local cb_streamopened = stream_callbacks.streamopened;
	local cb_streamclosed = stream_callbacks.streamclosed;
	local cb_error = stream_callbacks.error or function(session, e, stanza) error("XML stream error: "..tostring(e)..(stanza and ": "..tostring(stanza) or ""),2); end;
	local cb_handlestanza = stream_callbacks.handlestanza;
	cb_handleprogress = cb_handleprogress or dummy_cb;

	local stream_ns = stream_callbacks.stream_ns or xmlns_streams;
	local stream_tag = stream_callbacks.stream_tag or "stream";
	if stream_ns ~= "" then
		stream_tag = stream_ns..ns_separator..stream_tag;
	end
	local stream_error_tag = stream_ns..ns_separator..(stream_callbacks.error_tag or "error");

	local stream_default_ns = stream_callbacks.default_ns;

	local stack = {};
	local chardata, stanza = {};
	local stanza_size = 0;
	local non_streamns_depth = 0;
	function xml_handlers:StartElement(tagname, attr)
		if stanza and #chardata > 0 then
			-- We have some character data in the buffer
			t_insert(stanza, t_concat(chardata));
			chardata = {};
		end
		local curr_ns,name = tagname:match(ns_pattern);
		if name == "" then
			curr_ns, name = "", curr_ns;
		end

		if curr_ns ~= stream_default_ns or non_streamns_depth > 0 then
			attr.xmlns = curr_ns;
			non_streamns_depth = non_streamns_depth + 1;
		end

		for i=1,#attr do
			local k = attr[i];
			attr[i] = nil;
			local xmlk = xml_namespace[k];
			if xmlk then
				attr[xmlk] = attr[k];
				attr[k] = nil;
			end
		end

		if not stanza then --if we are not currently inside a stanza
			if lxp_supports_bytecount then
				stanza_size = self:getcurrentbytecount();
			end
			if session.notopen then
				if tagname == stream_tag then
					non_streamns_depth = 0;
					if cb_streamopened then
						if lxp_supports_bytecount then
							cb_handleprogress(stanza_size);
							stanza_size = 0;
						end
						cb_streamopened(session, attr);
					end
				else
					-- Garbage before stream?
					cb_error(session, "no-stream", tagname);
				end
				return;
			end
			if curr_ns == "jabber:client" and name ~= "iq" and name ~= "presence" and name ~= "message" then
				cb_error(session, "invalid-top-level-element");
			end

			stanza = setmetatable({ name = name, attr = attr, tags = {} }, stanza_mt);
		else -- we are inside a stanza, so add a tag
			if lxp_supports_bytecount then
				stanza_size = stanza_size + self:getcurrentbytecount();
			end
			t_insert(stack, stanza);
			local oldstanza = stanza;
			stanza = setmetatable({ name = name, attr = attr, tags = {} }, stanza_mt);
			t_insert(oldstanza, stanza);
			t_insert(oldstanza.tags, stanza);
		end
	end
	if lxp_supports_xmldecl then
		function xml_handlers:XmlDecl(version, encoding, standalone)
			if lxp_supports_bytecount then
				cb_handleprogress(self:getcurrentbytecount());
			end
		end
	end
	function xml_handlers:StartCdataSection()
		if lxp_supports_bytecount then
			if stanza then
				stanza_size = stanza_size + self:getcurrentbytecount();
			else
				cb_handleprogress(self:getcurrentbytecount());
			end
		end
	end
	function xml_handlers:EndCdataSection()
		if lxp_supports_bytecount then
			if stanza then
				stanza_size = stanza_size + self:getcurrentbytecount();
			else
				cb_handleprogress(self:getcurrentbytecount());
			end
		end
	end
	function xml_handlers:CharacterData(data)
		if stanza then
			if lxp_supports_bytecount then
				stanza_size = stanza_size + self:getcurrentbytecount();
			end
			t_insert(chardata, data);
		elseif lxp_supports_bytecount then
			cb_handleprogress(self:getcurrentbytecount());
		end
	end
	function xml_handlers:EndElement(tagname)
		if lxp_supports_bytecount then
			stanza_size = stanza_size + self:getcurrentbytecount()
		end
		if non_streamns_depth > 0 then
			non_streamns_depth = non_streamns_depth - 1;
		end
		if stanza then
			if #chardata > 0 then
				-- We have some character data in the buffer
				t_insert(stanza, t_concat(chardata));
				chardata = {};
			end
			-- Complete stanza
			if #stack == 0 then
				if lxp_supports_bytecount then
					cb_handleprogress(stanza_size);
				end
				stanza_size = 0;
				if tagname ~= stream_error_tag then
					cb_handlestanza(session, stanza);
				else
					cb_error(session, "stream-error", stanza);
				end
				stanza = nil;
			else
				stanza = t_remove(stack);
			end
		else
			if cb_streamclosed then
				cb_streamclosed(session);
			end
		end
	end

	local function restricted_handler(parser)
		cb_error(session, "parse-error", "restricted-xml", "Restricted XML, see RFC 6120 section 11.1.");
		if not parser.stop or not parser:stop() then
			error("Failed to abort parsing");
		end
	end

	if lxp_supports_doctype then
		xml_handlers.StartDoctypeDecl = restricted_handler;
	end
	xml_handlers.Comment = restricted_handler;
	xml_handlers.ProcessingInstruction = restricted_handler;

	local function reset()
		stanza, chardata, stanza_size = nil, {}, 0;
		stack = {};
	end

	local function set_session(stream, new_session)
		session = new_session;
	end

	return xml_handlers, { reset = reset, set_session = set_session };
end

local function new(session, stream_callbacks, stanza_size_limit)
	-- Used to track parser progress (e.g. to enforce size limits)
	local n_outstanding_bytes = 0;
	local handle_progress;
	if lxp_supports_bytecount then
		function handle_progress(n_parsed_bytes)
			n_outstanding_bytes = n_outstanding_bytes - n_parsed_bytes;
		end
		stanza_size_limit = stanza_size_limit or default_stanza_size_limit;
	elseif stanza_size_limit then
		error("Stanza size limits are not supported on this version of LuaExpat")
	end

	local handlers, meta = new_sax_handlers(session, stream_callbacks, handle_progress);
	local parser = new_parser(handlers, ns_separator, false);
	local parse = parser.parse;

	function session.open_stream(session, from, to)
		local send = session.sends2s or session.send;

		local attr = {
			["xmlns:stream"] = "http://etherx.jabber.org/streams",
			["xml:lang"] = "en",
			xmlns = stream_callbacks.default_ns,
			version = session.version and (session.version > 0 and "1.0" or nil),
			id = session.streamid,
			from = from or session.host, to = to,
		};
		if session.stream_attrs then
			session:stream_attrs(from, to, attr)
		end
		send("<?xml version='1.0'?>");
		send(st.stanza("stream:stream", attr):top_tag());
		return true;
	end

	return {
		reset = function ()
			parser = new_parser(handlers, ns_separator, false);
			parse = parser.parse;
			n_outstanding_bytes = 0;
			meta.reset();
		end,
		feed = function (self, data)
			if lxp_supports_bytecount then
				n_outstanding_bytes = n_outstanding_bytes + #data;
			end
			local ok, err = parse(parser, data);
			if lxp_supports_bytecount and n_outstanding_bytes > stanza_size_limit then
				return nil, "stanza-too-large";
			end
			return ok, err;
		end,
		set_session = meta.set_session;
	};
end

return {
	ns_separator = ns_separator;
	ns_pattern = ns_pattern;
	new_sax_handlers = new_sax_handlers;
	new = new;
};
 end)
package.preload['util.jid'] = (function (...)
					local _ENV = _ENV;
					local function module(name, ...)
						local t = package.loaded[name] or _ENV[name] or { _NAME = name };
						package.loaded[name] = t;
						for i = 1, select("#", ...) do
							(select(i, ...))(t);
						end
						_ENV = t;
						_M = t;
						return t;
					end
				-- Prosody IM
-- Copyright (C) 2008-2010 Matthew Wild
-- Copyright (C) 2008-2010 Waqas Hussain
--
-- This project is MIT/X11 licensed. Please see the
-- COPYING file in the source package for more information.
--



local select = select;
local match, sub = string.match, string.sub;
local nodeprep = require "util.encodings".stringprep.nodeprep;
local nameprep = require "util.encodings".stringprep.nameprep;
local resourceprep = require "util.encodings".stringprep.resourceprep;

local escapes = {
	[" "] = "\\20"; ['"'] = "\\22";
	["&"] = "\\26"; ["'"] = "\\27";
	["/"] = "\\2f"; [":"] = "\\3a";
	["<"] = "\\3c"; [">"] = "\\3e";
	["@"] = "\\40"; ["\\"] = "\\5c";
};
local unescapes = {};
for k,v in pairs(escapes) do unescapes[v] = k; end

local _ENV = nil;

local function split(jid)
	if not jid then return; end
	local node, nodepos = match(jid, "^([^@/]+)@()");
	local host, hostpos = match(jid, "^([^@/]+)()", nodepos)
	if node and not host then return nil, nil, nil; end
	local resource = match(jid, "^/(.+)$", hostpos);
	if (not host) or ((not resource) and #jid >= hostpos) then return nil, nil, nil; end
	return node, host, resource;
end

local function bare(jid)
	local node, host = split(jid);
	if node and host then
		return node.."@"..host;
	end
	return host;
end

local function prepped_split(jid)
	local node, host, resource = split(jid);
	if host and host ~= "." then
		if sub(host, -1, -1) == "." then -- Strip empty root label
			host = sub(host, 1, -2);
		end
		host = nameprep(host);
		if not host then return; end
		if node then
			node = nodeprep(node);
			if not node then return; end
		end
		if resource then
			resource = resourceprep(resource);
			if not resource then return; end
		end
		return node, host, resource;
	end
end

local function join(node, host, resource)
	if not host then return end
	if node and resource then
		return node.."@"..host.."/"..resource;
	elseif node then
		return node.."@"..host;
	elseif resource then
		return host.."/"..resource;
	end
	return host;
end

local function prep(jid)
	local node, host, resource = prepped_split(jid);
	return join(node, host, resource);
end

local function compare(jid, acl)
	-- compare jid to single acl rule
	-- TODO compare to table of rules?
	local jid_node, jid_host, jid_resource = split(jid);
	local acl_node, acl_host, acl_resource = split(acl);
	if ((acl_node ~= nil and acl_node == jid_node) or acl_node == nil) and
		((acl_host ~= nil and acl_host == jid_host) or acl_host == nil) and
		((acl_resource ~= nil and acl_resource == jid_resource) or acl_resource == nil) then
		return true
	end
	return false
end

local function node(jid)
	return (select(1, split(jid)));
end

local function host(jid)
	return (select(2, split(jid)));
end

local function resource(jid)
	return (select(3, split(jid)));
end

local function escape(s) return s and (s:gsub(".", escapes)); end
local function unescape(s) return s and (s:gsub("\\%x%x", unescapes)); end

return {
	split = split;
	bare = bare;
	prepped_split = prepped_split;
	join = join;
	prep = prep;
	compare = compare;
	node = node;
	host = host;
	resource = resource;
	escape = escape;
	unescape = unescape;
};
 end)
package.preload['util.events'] = (function (...)
					local _ENV = _ENV;
					local function module(name, ...)
						local t = package.loaded[name] or _ENV[name] or { _NAME = name };
						package.loaded[name] = t;
						for i = 1, select("#", ...) do
							(select(i, ...))(t);
						end
						_ENV = t;
						_M = t;
						return t;
					end
				-- Prosody IM
-- Copyright (C) 2008-2010 Matthew Wild
-- Copyright (C) 2008-2010 Waqas Hussain
--
-- This project is MIT/X11 licensed. Please see the
-- COPYING file in the source package for more information.
--


local pairs = pairs;
local t_insert = table.insert;
local t_remove = table.remove;
local t_sort = table.sort;
local setmetatable = setmetatable;
local next = next;

local _ENV = nil;

local function new()
	-- Map event name to ordered list of handlers (lazily built): handlers[event_name] = array_of_handler_functions
	local handlers = {};
	-- Array of wrapper functions that wrap all events (nil if empty)
	local global_wrappers;
	-- Per-event wrappers: wrappers[event_name] = wrapper_function
	local wrappers = {};
	-- Event map: event_map[handler_function] = priority_number
	local event_map = {};
	-- Called on-demand to build handlers entries
	local function _rebuild_index(handlers, event)
		local _handlers = event_map[event];
		if not _handlers or next(_handlers) == nil then return; end
		local index = {};
		for handler in pairs(_handlers) do
			t_insert(index, handler);
		end
		t_sort(index, function(a, b) return _handlers[a] > _handlers[b]; end);
		handlers[event] = index;
		return index;
	end;
	setmetatable(handlers, { __index = _rebuild_index });
	local function add_handler(event, handler, priority)
		local map = event_map[event];
		if map then
			map[handler] = priority or 0;
		else
			map = {[handler] = priority or 0};
			event_map[event] = map;
		end
		handlers[event] = nil;
	end;
	local function remove_handler(event, handler)
		local map = event_map[event];
		if map then
			map[handler] = nil;
			handlers[event] = nil;
			if next(map) == nil then
				event_map[event] = nil;
			end
		end
	end;
	local function get_handlers(event)
		return handlers[event];
	end;
	local function add_handlers(handlers)
		for event, handler in pairs(handlers) do
			add_handler(event, handler);
		end
	end;
	local function remove_handlers(handlers)
		for event, handler in pairs(handlers) do
			remove_handler(event, handler);
		end
	end;
	local function _fire_event(event_name, event_data)
		local h = handlers[event_name];
		if h then
			for i=1,#h do
				local ret = h[i](event_data);
				if ret ~= nil then return ret; end
			end
		end
	end;
	local function fire_event(event_name, event_data)
		local w = wrappers[event_name] or global_wrappers;
		if w then
			local curr_wrapper = #w;
			local function c(event_name, event_data)
				curr_wrapper = curr_wrapper - 1;
				if curr_wrapper == 0 then
					if global_wrappers == nil or w == global_wrappers then
						return _fire_event(event_name, event_data);
					end
					w, curr_wrapper = global_wrappers, #global_wrappers;
					return w[curr_wrapper](c, event_name, event_data);
				else
					return w[curr_wrapper](c, event_name, event_data);
				end
			end
			return w[curr_wrapper](c, event_name, event_data);
		end
		return _fire_event(event_name, event_data);
	end
	local function add_wrapper(event_name, wrapper)
		local w;
		if event_name == false then
			w = global_wrappers;
			if not w then
				w = {};
				global_wrappers = w;
			end
		else
			w = wrappers[event_name];
			if not w then
				w = {};
				wrappers[event_name] = w;
			end
		end
		w[#w+1] = wrapper;
	end
	local function remove_wrapper(event_name, wrapper)
		local w;
		if event_name == false then
			w = global_wrappers;
		else
			w = wrappers[event_name];
		end
		if not w then return; end
		for i = #w, 1, -1 do
			if w[i] == wrapper then
				t_remove(w, i);
			end
		end
		if #w == 0 then
			if event_name == false then
				global_wrappers = nil;
			else
				wrappers[event_name] = nil;
			end
		end
	end
	return {
		add_handler = add_handler;
		remove_handler = remove_handler;
		add_handlers = add_handlers;
		remove_handlers = remove_handlers;
		get_handlers = get_handlers;
		wrappers = {
			add_handler = add_wrapper;
			remove_handler = remove_wrapper;
		};
		add_wrapper = add_wrapper;
		remove_wrapper = remove_wrapper;
		fire_event = fire_event;
		_handlers = handlers;
		_event_map = event_map;
	};
end

return {
	new = new;
};
 end)
package.preload['util.dataforms'] = (function (...)
					local _ENV = _ENV;
					local function module(name, ...)
						local t = package.loaded[name] or _ENV[name] or { _NAME = name };
						package.loaded[name] = t;
						for i = 1, select("#", ...) do
							(select(i, ...))(t);
						end
						_ENV = t;
						_M = t;
						return t;
					end
				-- Prosody IM
-- Copyright (C) 2008-2010 Matthew Wild
-- Copyright (C) 2008-2010 Waqas Hussain
-- 
-- This project is MIT/X11 licensed. Please see the
-- COPYING file in the source package for more information.
--

local setmetatable = setmetatable;
local pairs, ipairs = pairs, ipairs;
local tostring, type, next = tostring, type, next;
local t_concat = table.concat;
local st = require "util.stanza";
local jid_prep = require "util.jid".prep;

module "dataforms"

local xmlns_forms = 'jabber:x:data';

local form_t = {};
local form_mt = { __index = form_t };

function new(layout)
	return setmetatable(layout, form_mt);
end

function from_stanza(stanza)
	local layout = {
		title = stanza:get_child_text("title");
		instructions = stanza:get_child_text("instructions");
	};
	for tag in stanza:childtags("field") do
		local field = {
			name = tag.attr.var;
			label = tag.attr.label;
			type = tag.attr.type;
			required = tag:get_child("required") and true or nil;
			value = tag:get_child_text("value");
		};
		layout[#layout+1] = field;
		if field.type then
			local value = {};
			if field.type:match"list%-" then
				for tag in tag:childtags("option") do
					value[#value+1] = { label = tag.attr.label, value = tag:get_child_text("value") };
				end
				for tag in tag:childtags("value") do
					value[#value+1] = { label = tag.attr.label, value = tag:get_text(), default = true };
				end
			elseif field.type:match"%-multi" then
				for tag in tag:childtags("value") do
					value[#value+1] = tag.attr.label and { label = tag.attr.label, value = tag:get_text() } or tag:get_text();
				end
				if field.type == "text-multi" then
					field.value = t_concat(value, "\n");
				else
					field.value = value;
				end
			end
		end
	end
	return new(layout);
end

function form_t.form(layout, data, formtype)
	local form = st.stanza("x", { xmlns = xmlns_forms, type = formtype or "form" });
	if layout.title then
		form:tag("title"):text(layout.title):up();
	end
	if layout.instructions then
		form:tag("instructions"):text(layout.instructions):up();
	end
	for n, field in ipairs(layout) do
		local field_type = field.type or "text-single";
		-- Add field tag
		form:tag("field", { type = field_type, var = field.name, label = field.label });

		local value = (data and data[field.name]) or field.value;
		
		if value then
			-- Add value, depending on type
			if field_type == "hidden" then
				if type(value) == "table" then
					-- Assume an XML snippet
					form:tag("value")
						:add_child(value)
						:up();
				else
					form:tag("value"):text(tostring(value)):up();
				end
			elseif field_type == "boolean" then
				form:tag("value"):text((value and "1") or "0"):up();
			elseif field_type == "fixed" then
				
			elseif field_type == "jid-multi" then
				for _, jid in ipairs(value) do
					form:tag("value"):text(jid):up();
				end
			elseif field_type == "jid-single" then
				form:tag("value"):text(value):up();
			elseif field_type == "text-single" or field_type == "text-private" then
				form:tag("value"):text(value):up();
			elseif field_type == "text-multi" then
				-- Split into multiple <value> tags, one for each line
				for line in value:gmatch("([^\r\n]+)\r?\n*") do
					form:tag("value"):text(line):up();
				end
			elseif field_type == "list-single" then
				local has_default = false;
				for _, val in ipairs(value) do
					if type(val) == "table" then
						form:tag("option", { label = val.label }):tag("value"):text(val.value):up():up();
						if val.default and (not has_default) then
							form:tag("value"):text(val.value):up();
							has_default = true;
						end
					else
						form:tag("option", { label= val }):tag("value"):text(tostring(val)):up():up();
					end
				end
			elseif field_type == "list-multi" then
				for _, val in ipairs(value) do
					if type(val) == "table" then
						form:tag("option", { label = val.label }):tag("value"):text(val.value):up():up();
						if val.default then
							form:tag("value"):text(val.value):up();
						end
					else
						form:tag("option", { label= val }):tag("value"):text(tostring(val)):up():up();
					end
				end
			end
		end
		
		if field.required then
			form:tag("required"):up();
		end
		
		-- Jump back up to list of fields
		form:up();
	end
	return form;
end

local field_readers = {};

function form_t.data(layout, stanza)
	local data = {};
	local errors = {};

	for _, field in ipairs(layout) do
		local tag;
		for field_tag in stanza:childtags() do
			if field.name == field_tag.attr.var then
				tag = field_tag;
				break;
			end
		end

		if not tag then
			if field.required then
				errors[field.name] = "Required value missing";
			end
		else
			local reader = field_readers[field.type];
			if reader then
				data[field.name], errors[field.name] = reader(tag, field.required);
			end
		end
	end
	if next(errors) then
		return data, errors;
	end
	return data;
end

field_readers["text-single"] =
	function (field_tag, required)
		local data = field_tag:get_child_text("value");
		if data and #data > 0 then
			return data
		elseif required then
			return nil, "Required value missing";
		end
	end

field_readers["text-private"] =
	field_readers["text-single"];

field_readers["jid-single"] =
	function (field_tag, required)
		local raw_data = field_tag:get_child_text("value")
		local data = jid_prep(raw_data);
		if data and #data > 0 then
			return data
		elseif raw_data then
			return nil, "Invalid JID: " .. raw_data;
		elseif required then
			return nil, "Required value missing";
		end
	end

field_readers["jid-multi"] =
	function (field_tag, required)
		local result = {};
		local err = {};
		for value_tag in field_tag:childtags("value") do
			local raw_value = value_tag:get_text();
			local value = jid_prep(raw_value);
			result[#result+1] = value;
			if raw_value and not value then
				err[#err+1] = ("Invalid JID: " .. raw_value);
			end
		end
		if #result > 0 then
			return result, (#err > 0 and t_concat(err, "\n") or nil);
		elseif required then
			return nil, "Required value missing";
		end
	end

field_readers["list-multi"] =
	function (field_tag, required)
		local result = {};
		for value in field_tag:childtags("value") do
			result[#result+1] = value:get_text();
		end
		return result, (required and #result == 0 and "Required value missing" or nil);
	end

field_readers["text-multi"] =
	function (field_tag, required)
		local data, err = field_readers["list-multi"](field_tag, required);
		if data then
			data = t_concat(data, "\n");
		end
		return data, err;
	end

field_readers["list-single"] =
	field_readers["text-single"];

local boolean_values = {
	["1"] = true, ["true"] = true,
	["0"] = false, ["false"] = false,
};

field_readers["boolean"] =
	function (field_tag, required)
		local raw_value = field_tag:get_child_text("value");
		local value = boolean_values[raw_value ~= nil and raw_value];
		if value ~= nil then
			return value;
		elseif raw_value then
			return nil, "Invalid boolean representation";
		elseif required then
			return nil, "Required value missing";
		end
	end

field_readers["hidden"] =
	function (field_tag)
		return field_tag:get_child_text("value");
	end

return _M;


--[=[

Layout:
{

	title = "MUC Configuration",
	instructions = [[Use this form to configure options for this MUC room.]],

	{ name = "FORM_TYPE", type = "hidden", required = true };
	{ name = "field-name", type = "field-type", required = false };
}


--]=]
 end)
package.preload['util.caps'] = (function (...)
					local _ENV = _ENV;
					local function module(name, ...)
						local t = package.loaded[name] or _ENV[name] or { _NAME = name };
						package.loaded[name] = t;
						for i = 1, select("#", ...) do
							(select(i, ...))(t);
						end
						_ENV = t;
						_M = t;
						return t;
					end
				-- Prosody IM
-- Copyright (C) 2008-2010 Matthew Wild
-- Copyright (C) 2008-2010 Waqas Hussain
--
-- This project is MIT/X11 licensed. Please see the
-- COPYING file in the source package for more information.
--

local base64 = require "util.encodings".base64.encode;
local sha1 = require "util.hashes".sha1;

local t_insert, t_sort, t_concat = table.insert, table.sort, table.concat;
local ipairs = ipairs;

local _ENV = nil;

local function calculate_hash(disco_info)
	local identities, features, extensions = {}, {}, {};
	for _, tag in ipairs(disco_info) do
		if tag.name == "identity" then
			t_insert(identities, (tag.attr.category or "").."\0"..(tag.attr.type or "").."\0"..(tag.attr["xml:lang"] or "").."\0"..(tag.attr.name or ""));
		elseif tag.name == "feature" then
			t_insert(features, tag.attr.var or "");
		elseif tag.name == "x" and tag.attr.xmlns == "jabber:x:data" then
			local form = {};
			local FORM_TYPE;
			for _, field in ipairs(tag.tags) do
				if field.name == "field" and field.attr.var then
					local values = {};
					for _, val in ipairs(field.tags) do
						val = #val.tags == 0 and val:get_text();
						if val then t_insert(values, val); end
					end
					t_sort(values);
					if field.attr.var == "FORM_TYPE" then
						FORM_TYPE = values[1];
					elseif #values > 0 then
						t_insert(form, field.attr.var.."\0"..t_concat(values, "<"));
					else
						t_insert(form, field.attr.var);
					end
				end
			end
			t_sort(form);
			form = t_concat(form, "<");
			if FORM_TYPE then form = FORM_TYPE.."\0"..form; end
			t_insert(extensions, form);
		end
	end
	t_sort(identities);
	t_sort(features);
	t_sort(extensions);
	if #identities > 0 then identities = t_concat(identities, "<"):gsub("%z", "/").."<"; else identities = ""; end
	if #features > 0 then features = t_concat(features, "<").."<"; else features = ""; end
	if #extensions > 0 then extensions = t_concat(extensions, "<"):gsub("%z", "<").."<"; else extensions = ""; end
	local S = identities..features..extensions;
	local ver = base64(sha1(S));
	return ver, S;
end

return {
	calculate_hash = calculate_hash;
};
 end)
package.preload['util.vcard'] = (function (...)
					local _ENV = _ENV;
					local function module(name, ...)
						local t = package.loaded[name] or _ENV[name] or { _NAME = name };
						package.loaded[name] = t;
						for i = 1, select("#", ...) do
							(select(i, ...))(t);
						end
						_ENV = t;
						_M = t;
						return t;
					end
				-- Copyright (C) 2011-2012 Kim Alvefur
-- 
-- This project is MIT/X11 licensed. Please see the
-- COPYING file in the source package for more information.
--

-- TODO
-- Fix folding.

local st = require "util.stanza";
local t_insert, t_concat = table.insert, table.concat;
local type = type;
local next, pairs, ipairs = next, pairs, ipairs;

local from_text, to_text, from_xep54, to_xep54;

local line_sep = "\n";

local vCard_dtd; -- See end of file

local function fold_line()
	error "Not implemented" --TODO
end
local function unfold_line()
	error "Not implemented"
	-- gsub("\r?\n[ \t]([^\r\n])", "%1");
end

local function vCard_esc(s)
	return s:gsub("[,:;\\]", "\\%1"):gsub("\n","\\n");
end

local function vCard_unesc(s)
	return s:gsub("\\?[\\nt:;,]", {
		["\\\\"] = "\\",
		["\\n"] = "\n",
		["\\r"] = "\r",
		["\\t"] = "\t",
		["\\:"] = ":", -- FIXME Shouldn't need to espace : in values, just params
		["\\;"] = ";",
		["\\,"] = ",",
		[":"] = "\29",
		[";"] = "\30",
		[","] = "\31",
	});
end

local function item_to_xep54(item)
	local t = st.stanza(item.name, { xmlns = "vcard-temp" });

	local prop_def = vCard_dtd[item.name];
	if prop_def == "text" then
		t:text(item[1]);
	elseif type(prop_def) == "table" then
		if prop_def.types and item.TYPE then
			if type(item.TYPE) == "table" then
				for _,v in pairs(prop_def.types) do
					for _,typ in pairs(item.TYPE) do
						if typ:upper() == v then
							t:tag(v):up();
							break;
						end
					end
				end
			else
				t:tag(item.TYPE:upper()):up();
			end
		end

		if prop_def.props then
			for _,v in pairs(prop_def.props) do
				if item[v] then
					t:tag(v):up();
				end
			end
		end

		if prop_def.value then
			t:tag(prop_def.value):text(item[1]):up();
		elseif prop_def.values then
			local prop_def_values = prop_def.values;
			local repeat_last = prop_def_values.behaviour == "repeat-last" and prop_def_values[#prop_def_values];
			for i=1,#item do
				t:tag(prop_def.values[i] or repeat_last):text(item[i]):up();
			end
		end
	end

	return t;
end

local function vcard_to_xep54(vCard)
	local t = st.stanza("vCard", { xmlns = "vcard-temp" });
	for i=1,#vCard do
		t:add_child(item_to_xep54(vCard[i]));
	end
	return t;
end

function to_xep54(vCards)
	if not vCards[1] or vCards[1].name then
		return vcard_to_xep54(vCards)
	else
		local t = st.stanza("xCard", { xmlns = "vcard-temp" });
		for i=1,#vCards do
			t:add_child(vcard_to_xep54(vCards[i]));
		end
		return t;
	end
end

function from_text(data)
	data = data -- unfold and remove empty lines
		:gsub("\r\n","\n")
		:gsub("\n ", "")
		:gsub("\n\n+","\n");
	local vCards = {};
	local c; -- current item
	for line in data:gmatch("[^\n]+") do
		local line = vCard_unesc(line);
		local name, params, value = line:match("^([-%a]+)(\30?[^\29]*)\29(.*)$");
		value = value:gsub("\29",":");
		if #params > 0 then
			local _params = {};
			for k,isval,v in params:gmatch("\30([^=]+)(=?)([^\30]*)") do
				k = k:upper();
				local _vt = {};
				for _p in v:gmatch("[^\31]+") do
					_vt[#_vt+1]=_p
					_vt[_p]=true;
				end
				if isval == "=" then
					_params[k]=_vt;
				else
					_params[k]=true;
				end
			end
			params = _params;
		end
		if name == "BEGIN" and value == "VCARD" then
			c = {};
			vCards[#vCards+1] = c;
		elseif name == "END" and value == "VCARD" then
			c = nil;
		elseif c and vCard_dtd[name] then
			local dtd = vCard_dtd[name];
			local p = { name = name };
			c[#c+1]=p;
			--c[name]=p;
			local up = c;
			c = p;
			if dtd.types then
				for _, t in ipairs(dtd.types) do
					local t = t:lower();
					if ( params.TYPE and params.TYPE[t] == true)
							or params[t] == true then
						c.TYPE=t;
					end
				end
			end
			if dtd.props then
				for _, p in ipairs(dtd.props) do
					if params[p] then
						if params[p] == true then
							c[p]=true;
						else
							for _, prop in ipairs(params[p]) do
								c[p]=prop;
							end
						end
					end
				end
			end
			if dtd == "text" or dtd.value then
				t_insert(c, value);
			elseif dtd.values then
				local value = "\30"..value;
				for p in value:gmatch("\30([^\30]*)") do
					t_insert(c, p);
				end
			end
			c = up;
		end
	end
	return vCards;
end

local function item_to_text(item)
	local value = {};
	for i=1,#item do
		value[i] = vCard_esc(item[i]);
	end
	value = t_concat(value, ";");

	local params = "";
	for k,v in pairs(item) do
		if type(k) == "string" and k ~= "name" then
			params = params .. (";%s=%s"):format(k, type(v) == "table" and t_concat(v,",") or v);
		end
	end

	return ("%s%s:%s"):format(item.name, params, value)
end

local function vcard_to_text(vcard)
	local t={};
	t_insert(t, "BEGIN:VCARD")
	for i=1,#vcard do
		t_insert(t, item_to_text(vcard[i]));
	end
	t_insert(t, "END:VCARD")
	return t_concat(t, line_sep);
end

function to_text(vCards)
	if vCards[1] and vCards[1].name then
		return vcard_to_text(vCards)
	else
		local t = {};
		for i=1,#vCards do
			t[i]=vcard_to_text(vCards[i]);
		end
		return t_concat(t, line_sep);
	end
end

local function from_xep54_item(item)
	local prop_name = item.name;
	local prop_def = vCard_dtd[prop_name];

	local prop = { name = prop_name };

	if prop_def == "text" then
		prop[1] = item:get_text();
	elseif type(prop_def) == "table" then
		if prop_def.value then --single item
			prop[1] = item:get_child_text(prop_def.value) or "";
		elseif prop_def.values then --array
			local value_names = prop_def.values;
			if value_names.behaviour == "repeat-last" then
				for i=1,#item.tags do
					t_insert(prop, item.tags[i]:get_text() or "");
				end
			else
				for i=1,#value_names do
					t_insert(prop, item:get_child_text(value_names[i]) or "");
				end
			end
		elseif prop_def.names then
			local names = prop_def.names;
			for i=1,#names do
				if item:get_child(names[i]) then
					prop[1] = names[i];
					break;
				end
			end
		end
		
		if prop_def.props_verbatim then
			for k,v in pairs(prop_def.props_verbatim) do
				prop[k] = v;
			end
		end

		if prop_def.types then
			local types = prop_def.types;
			prop.TYPE = {};
			for i=1,#types do
				if item:get_child(types[i]) then
					t_insert(prop.TYPE, types[i]:lower());
				end
			end
			if #prop.TYPE == 0 then
				prop.TYPE = nil;
			end
		end

		-- A key-value pair, within a key-value pair?
		if prop_def.props then
			local params = prop_def.props;
			for i=1,#params do
				local name = params[i]
				local data = item:get_child_text(name);
				if data then
					prop[name] = prop[name] or {};
					t_insert(prop[name], data);
				end
			end
		end
	else
		return nil
	end

	return prop;
end

local function from_xep54_vCard(vCard)
	local tags = vCard.tags;
	local t = {};
	for i=1,#tags do
		t_insert(t, from_xep54_item(tags[i]));
	end
	return t
end

function from_xep54(vCard)
	if vCard.attr.xmlns ~= "vcard-temp" then
		return nil, "wrong-xmlns";
	end
	if vCard.name == "xCard" then -- A collection of vCards
		local t = {};
		local vCards = vCard.tags;
		for i=1,#vCards do
			t[i] = from_xep54_vCard(vCards[i]);
		end
		return t
	elseif vCard.name == "vCard" then -- A single vCard
		return from_xep54_vCard(vCard)
	end
end

-- This was adapted from http://xmpp.org/extensions/xep-0054.html#dtd
vCard_dtd = {
	VERSION = "text", --MUST be 3.0, so parsing is redundant
	FN = "text",
	N = {
		values = {
			"FAMILY",
			"GIVEN",
			"MIDDLE",
			"PREFIX",
			"SUFFIX",
		},
	},
	NICKNAME = "text",
	PHOTO = {
		props_verbatim = { ENCODING = { "b" } },
		props = { "TYPE" },
		value = "BINVAL", --{ "EXTVAL", },
	},
	BDAY = "text",
	ADR = {
		types = {
			"HOME",
			"WORK", 
			"POSTAL", 
			"PARCEL", 
			"DOM",
			"INTL",
			"PREF", 
		},
		values = {
			"POBOX",
			"EXTADD",
			"STREET",
			"LOCALITY",
			"REGION",
			"PCODE",
			"CTRY",
		}
	},
	LABEL = {
		types = {
			"HOME", 
			"WORK", 
			"POSTAL", 
			"PARCEL", 
			"DOM",
			"INTL", 
			"PREF", 
		},
		value = "LINE",
	},
	TEL = {
		types = {
			"HOME", 
			"WORK", 
			"VOICE", 
			"FAX", 
			"PAGER", 
			"MSG", 
			"CELL", 
			"VIDEO", 
			"BBS", 
			"MODEM", 
			"ISDN", 
			"PCS", 
			"PREF", 
		},
		value = "NUMBER",
	},
	EMAIL = {
		types = {
			"HOME", 
			"WORK", 
			"INTERNET", 
			"PREF", 
			"X400", 
		},
		value = "USERID",
	},
	JABBERID = "text",
	MAILER = "text",
	TZ = "text",
	GEO = {
		values = {
			"LAT",
			"LON",
		},
	},
	TITLE = "text",
	ROLE = "text",
	LOGO = "copy of PHOTO",
	AGENT = "text",
	ORG = {
		values = {
			behaviour = "repeat-last",
			"ORGNAME",
			"ORGUNIT",
		}
	},
	CATEGORIES = {
		values = "KEYWORD",
	},
	NOTE = "text",
	PRODID = "text",
	REV = "text",
	SORTSTRING = "text",
	SOUND = "copy of PHOTO",
	UID = "text",
	URL = "text",
	CLASS = {
		names = { -- The item.name is the value if it's one of these.
			"PUBLIC",
			"PRIVATE",
			"CONFIDENTIAL",
		},
	},
	KEY = {
		props = { "TYPE" },
		value = "CRED",
	},
	DESC = "text",
};
vCard_dtd.LOGO = vCard_dtd.PHOTO;
vCard_dtd.SOUND = vCard_dtd.PHOTO;

return {
	from_text = from_text;
	to_text = to_text;

	from_xep54 = from_xep54;
	to_xep54 = to_xep54;

	-- COMPAT:
	lua_to_text = to_text;
	lua_to_xep54 = to_xep54;

	text_to_lua = from_text;
	text_to_xep54 = function (...) return to_xep54(from_text(...)); end;

	xep54_to_lua = from_xep54;
	xep54_to_text = function (...) return to_text(from_xep54(...)) end;
};
 end)
package.preload['util.logger'] = (function (...)
					local _ENV = _ENV;
					local function module(name, ...)
						local t = package.loaded[name] or _ENV[name] or { _NAME = name };
						package.loaded[name] = t;
						for i = 1, select("#", ...) do
							(select(i, ...))(t);
						end
						_ENV = t;
						_M = t;
						return t;
					end
				-- Prosody IM
-- Copyright (C) 2008-2010 Matthew Wild
-- Copyright (C) 2008-2010 Waqas Hussain
--
-- This project is MIT/X11 licensed. Please see the
-- COPYING file in the source package for more information.
--
-- luacheck: ignore 213/level

local pairs = pairs;

local _ENV = nil;

local level_sinks = {};

local make_logger;

local function init(name)
	local log_debug = make_logger(name, "debug");
	local log_info = make_logger(name, "info");
	local log_warn = make_logger(name, "warn");
	local log_error = make_logger(name, "error");

	return function (level, message, ...)
			if level == "debug" then
				return log_debug(message, ...);
			elseif level == "info" then
				return log_info(message, ...);
			elseif level == "warn" then
				return log_warn(message, ...);
			elseif level == "error" then
				return log_error(message, ...);
			end
		end
end

function make_logger(source_name, level)
	local level_handlers = level_sinks[level];
	if not level_handlers then
		level_handlers = {};
		level_sinks[level] = level_handlers;
	end

	local logger = function (message, ...)
		for i = 1,#level_handlers do
			level_handlers[i](source_name, level, message, ...);
		end
	end

	return logger;
end

local function reset()
	for level, handler_list in pairs(level_sinks) do
		-- Clear all handlers for this level
		for i = 1, #handler_list do
			handler_list[i] = nil;
		end
	end
end

local function add_level_sink(level, sink_function)
	if not level_sinks[level] then
		level_sinks[level] = { sink_function };
	else
		level_sinks[level][#level_sinks[level] + 1 ] = sink_function;
	end
end

return {
	init = init;
	make_logger = make_logger;
	reset = reset;
	add_level_sink = add_level_sink;
	new = make_logger;
};
 end)
package.preload['util.datetime'] = (function (...)
					local _ENV = _ENV;
					local function module(name, ...)
						local t = package.loaded[name] or _ENV[name] or { _NAME = name };
						package.loaded[name] = t;
						for i = 1, select("#", ...) do
							(select(i, ...))(t);
						end
						_ENV = t;
						_M = t;
						return t;
					end
				-- Prosody IM
-- Copyright (C) 2008-2010 Matthew Wild
-- Copyright (C) 2008-2010 Waqas Hussain
--
-- This project is MIT/X11 licensed. Please see the
-- COPYING file in the source package for more information.
--


-- XEP-0082: XMPP Date and Time Profiles

local os_date = os.date;
local os_time = os.time;
local os_difftime = os.difftime;
local tonumber = tonumber;

local _ENV = nil;

local function date(t)
	return os_date("!%Y-%m-%d", t);
end

local function datetime(t)
	return os_date("!%Y-%m-%dT%H:%M:%SZ", t);
end

local function time(t)
	return os_date("!%H:%M:%S", t);
end

local function legacy(t)
	return os_date("!%Y%m%dT%H:%M:%S", t);
end

local function parse(s)
	if s then
		local year, month, day, hour, min, sec, tzd;
		year, month, day, hour, min, sec, tzd = s:match("^(%d%d%d%d)%-?(%d%d)%-?(%d%d)T(%d%d):(%d%d):(%d%d)%.?%d*([Z+%-]?.*)$");
		if year then
			local time_offset = os_difftime(os_time(os_date("*t")), os_time(os_date("!*t"))); -- to deal with local timezone
			local tzd_offset = 0;
			if tzd ~= "" and tzd ~= "Z" then
				local sign, h, m = tzd:match("([+%-])(%d%d):?(%d*)");
				if not sign then return; end
				if #m ~= 2 then m = "0"; end
				h, m = tonumber(h), tonumber(m);
				tzd_offset = h * 60 * 60 + m * 60;
				if sign == "-" then tzd_offset = -tzd_offset; end
			end
			sec = (sec + time_offset) - tzd_offset;
			return os_time({year=year, month=month, day=day, hour=hour, min=min, sec=sec, isdst=false});
		end
	end
end

return {
	date     = date;
	datetime = datetime;
	time     = time;
	legacy   = legacy;
	parse    = parse;
};
 end)
package.preload['util.json'] = (function (...)
					local _ENV = _ENV;
					local function module(name, ...)
						local t = package.loaded[name] or _ENV[name] or { _NAME = name };
						package.loaded[name] = t;
						for i = 1, select("#", ...) do
							(select(i, ...))(t);
						end
						_ENV = t;
						_M = t;
						return t;
					end
				-- Prosody IM
-- Copyright (C) 2008-2010 Matthew Wild
-- Copyright (C) 2008-2010 Waqas Hussain
--
-- This project is MIT/X11 licensed. Please see the
-- COPYING file in the source package for more information.
--

local type = type;
local t_insert, t_concat, t_remove, t_sort = table.insert, table.concat, table.remove, table.sort;
local s_char = string.char;
local tostring, tonumber = tostring, tonumber;
local pairs, ipairs = pairs, ipairs;
local next = next;
local getmetatable, setmetatable = getmetatable, setmetatable;
local print = print;

local has_array, array = pcall(require, "util.array");
local array_mt = has_array and getmetatable(array()) or {};

--module("json")
local module = {};

local null = setmetatable({}, { __tostring = function() return "null"; end; });
module.null = null;

local escapes = {
	["\""] = "\\\"", ["\\"] = "\\\\", ["\b"] = "\\b",
	["\f"] = "\\f", ["\n"] = "\\n", ["\r"] = "\\r", ["\t"] = "\\t"};
local unescapes = {
	["\""] = "\"", ["\\"] = "\\", ["/"] = "/",
	b = "\b", f = "\f", n = "\n", r = "\r", t = "\t"};
for i=0,31 do
	local ch = s_char(i);
	if not escapes[ch] then escapes[ch] = ("\\u%.4X"):format(i); end
end

local function codepoint_to_utf8(code)
	if code < 0x80 then return s_char(code); end
	local bits0_6 = code % 64;
	if code < 0x800 then
		local bits6_5 = (code - bits0_6) / 64;
		return s_char(0x80 + 0x40 + bits6_5, 0x80 + bits0_6);
	end
	local bits0_12 = code % 4096;
	local bits6_6 = (bits0_12 - bits0_6) / 64;
	local bits12_4 = (code - bits0_12) / 4096;
	return s_char(0x80 + 0x40 + 0x20 + bits12_4, 0x80 + bits6_6, 0x80 + bits0_6);
end

local valid_types = {
	number  = true,
	string  = true,
	table   = true,
	boolean = true
};
local special_keys = {
	__array = true;
	__hash  = true;
};

local simplesave, tablesave, arraysave, stringsave;

function stringsave(o, buffer)
	-- FIXME do proper utf-8 and binary data detection
	t_insert(buffer, "\""..(o:gsub(".", escapes)).."\"");
end

function arraysave(o, buffer)
	t_insert(buffer, "[");
	if next(o) then
		for _, v in ipairs(o) do
			simplesave(v, buffer);
			t_insert(buffer, ",");
		end
		t_remove(buffer);
	end
	t_insert(buffer, "]");
end

function tablesave(o, buffer)
	local __array = {};
	local __hash = {};
	local hash = {};
	for i,v in ipairs(o) do
		__array[i] = v;
	end
	for k,v in pairs(o) do
		local ktype, vtype = type(k), type(v);
		if valid_types[vtype] or v == null then
			if ktype == "string" and not special_keys[k] then
				hash[k] = v;
			elseif (valid_types[ktype] or k == null) and __array[k] == nil then
				__hash[k] = v;
			end
		end
	end
	if next(__hash) ~= nil or next(hash) ~= nil or next(__array) == nil then
		t_insert(buffer, "{");
		local mark = #buffer;
		if buffer.ordered then
			local keys = {};
			for k in pairs(hash) do
				t_insert(keys, k);
			end
			t_sort(keys);
			for _,k in ipairs(keys) do
				stringsave(k, buffer);
				t_insert(buffer, ":");
				simplesave(hash[k], buffer);
				t_insert(buffer, ",");
			end
		else
			for k,v in pairs(hash) do
				stringsave(k, buffer);
				t_insert(buffer, ":");
				simplesave(v, buffer);
				t_insert(buffer, ",");
			end
		end
		if next(__hash) ~= nil then
			t_insert(buffer, "\"__hash\":[");
			for k,v in pairs(__hash) do
				simplesave(k, buffer);
				t_insert(buffer, ",");
				simplesave(v, buffer);
				t_insert(buffer, ",");
			end
			t_remove(buffer);
			t_insert(buffer, "]");
			t_insert(buffer, ",");
		end
		if next(__array) then
			t_insert(buffer, "\"__array\":");
			arraysave(__array, buffer);
			t_insert(buffer, ",");
		end
		if mark ~= #buffer then t_remove(buffer); end
		t_insert(buffer, "}");
	else
		arraysave(__array, buffer);
	end
end

function simplesave(o, buffer)
	local t = type(o);
	if o == null then
		t_insert(buffer, "null");
	elseif t == "number" then
		t_insert(buffer, tostring(o));
	elseif t == "string" then
		stringsave(o, buffer);
	elseif t == "table" then
		local mt = getmetatable(o);
		if mt == array_mt then
			arraysave(o, buffer);
		else
			tablesave(o, buffer);
		end
	elseif t == "boolean" then
		t_insert(buffer, (o and "true" or "false"));
	else
		t_insert(buffer, "null");
	end
end

function module.encode(obj)
	local t = {};
	simplesave(obj, t);
	return t_concat(t);
end
function module.encode_ordered(obj)
	local t = { ordered = true };
	simplesave(obj, t);
	return t_concat(t);
end
function module.encode_array(obj)
	local t = {};
	arraysave(obj, t);
	return t_concat(t);
end

-----------------------------------


local function _skip_whitespace(json, index)
	return json:find("[^ \t\r\n]", index) or index; -- no need to check \r\n, we converted those to \t
end
local function _fixobject(obj)
	local __array = obj.__array;
	if __array then
		obj.__array = nil;
		for _, v in ipairs(__array) do
			t_insert(obj, v);
		end
	end
	local __hash = obj.__hash;
	if __hash then
		obj.__hash = nil;
		local k;
		for _, v in ipairs(__hash) do
			if k ~= nil then
				obj[k] = v; k = nil;
			else
				k = v;
			end
		end
	end
	return obj;
end
local _readvalue, _readstring;
local function _readobject(json, index)
	local o = {};
	while true do
		local key, val;
		index = _skip_whitespace(json, index + 1);
		if json:byte(index) ~= 0x22 then -- "\""
			if json:byte(index) == 0x7d then return o, index + 1; end -- "}"
			return nil, "key expected";
		end
		key, index = _readstring(json, index);
		if key == nil then return nil, index; end
		index = _skip_whitespace(json, index);
		if json:byte(index) ~= 0x3a then return nil, "colon expected"; end -- ":"
		val, index = _readvalue(json, index + 1);
		if val == nil then return nil, index; end
		o[key] = val;
		index = _skip_whitespace(json, index);
		local b = json:byte(index);
		if b == 0x7d then return _fixobject(o), index + 1; end -- "}"
		if b ~= 0x2c then return nil, "object eof"; end -- ","
	end
end
local function _readarray(json, index)
	local a = {};
	local oindex = index;
	while true do
		local val;
		val, index = _readvalue(json, index + 1);
		if val == nil then
			if json:byte(oindex + 1) == 0x5d then return setmetatable(a, array_mt), oindex + 2; end -- "]"
			return val, index;
		end
		t_insert(a, val);
		index = _skip_whitespace(json, index);
		local b = json:byte(index);
		if b == 0x5d then return setmetatable(a, array_mt), index + 1; end -- "]"
		if b ~= 0x2c then return nil, "array eof"; end -- ","
	end
end
local _unescape_error;
local function _unescape_surrogate_func(x)
	local lead, trail = tonumber(x:sub(3, 6), 16), tonumber(x:sub(9, 12), 16);
	local codepoint = lead * 0x400 + trail - 0x35FDC00;
	local a = codepoint % 64;
	codepoint = (codepoint - a) / 64;
	local b = codepoint % 64;
	codepoint = (codepoint - b) / 64;
	local c = codepoint % 64;
	codepoint = (codepoint - c) / 64;
	return s_char(0xF0 + codepoint, 0x80 + c, 0x80 + b, 0x80 + a);
end
local function _unescape_func(x)
	x = x:match("%x%x%x%x", 3);
	if x then
		--if x >= 0xD800 and x <= 0xDFFF then _unescape_error = true; end -- bad surrogate pair
		return codepoint_to_utf8(tonumber(x, 16));
	end
	_unescape_error = true;
end
function _readstring(json, index)
	index = index + 1;
	local endindex = json:find("\"", index, true);
	if endindex then
		local s = json:sub(index, endindex - 1);
		--if s:find("[%z-\31]") then return nil, "control char in string"; end
		-- FIXME handle control characters
		_unescape_error = nil;
		--s = s:gsub("\\u[dD][89abAB]%x%x\\u[dD][cdefCDEF]%x%x", _unescape_surrogate_func);
		-- FIXME handle escapes beyond BMP
		s = s:gsub("\\u.?.?.?.?", _unescape_func);
		if _unescape_error then return nil, "invalid escape"; end
		return s, endindex + 1;
	end
	return nil, "string eof";
end
local function _readnumber(json, index)
	local m = json:match("[0-9%.%-eE%+]+", index); -- FIXME do strict checking
	return tonumber(m), index + #m;
end
local function _readnull(json, index)
	local a, b, c = json:byte(index + 1, index + 3);
	if a == 0x75 and b == 0x6c and c == 0x6c then
		return null, index + 4;
	end
	return nil, "null parse failed";
end
local function _readtrue(json, index)
	local a, b, c = json:byte(index + 1, index + 3);
	if a == 0x72 and b == 0x75 and c == 0x65 then
		return true, index + 4;
	end
	return nil, "true parse failed";
end
local function _readfalse(json, index)
	local a, b, c, d = json:byte(index + 1, index + 4);
	if a == 0x61 and b == 0x6c and c == 0x73 and d == 0x65 then
		return false, index + 5;
	end
	return nil, "false parse failed";
end
function _readvalue(json, index)
	index = _skip_whitespace(json, index);
	local b = json:byte(index);
	-- TODO try table lookup instead of if-else?
	if b == 0x7B then -- "{"
		return _readobject(json, index);
	elseif b == 0x5B then -- "["
		return _readarray(json, index);
	elseif b == 0x22 then -- "\""
		return _readstring(json, index);
	elseif b ~= nil and b >= 0x30 and b <= 0x39 or b == 0x2d then -- "0"-"9" or "-"
		return _readnumber(json, index);
	elseif b == 0x6e then -- "n"
		return _readnull(json, index);
	elseif b == 0x74 then -- "t"
		return _readtrue(json, index);
	elseif b == 0x66 then -- "f"
		return _readfalse(json, index);
	else
		return nil, "value expected";
	end
end
local first_escape = {
	["\\\""] = "\\u0022";
	["\\\\"] = "\\u005c";
	["\\/" ] = "\\u002f";
	["\\b" ] = "\\u0008";
	["\\f" ] = "\\u000C";
	["\\n" ] = "\\u000A";
	["\\r" ] = "\\u000D";
	["\\t" ] = "\\u0009";
	["\\u" ] = "\\u";
};

function module.decode(json)
	json = json:gsub("\\.", first_escape) -- get rid of all escapes except \uXXXX, making string parsing much simpler
		--:gsub("[\r\n]", "\t"); -- \r\n\t are equivalent, we care about none of them, and none of them can be in strings

	-- TODO do encoding verification

	local val, index = _readvalue(json, 1);
	if val == nil then return val, index; end
	if json:find("[^ \t\r\n]", index) then return nil, "garbage at eof"; end

	return val;
end

function module.test(object)
	local encoded = module.encode(object);
	local decoded = module.decode(encoded);
	local recoded = module.encode(decoded);
	if encoded ~= recoded then
		print("FAILED");
		print("encoded:", encoded);
		print("recoded:", recoded);
	else
		print(encoded);
	end
	return encoded == recoded;
end

return module;
 end)
package.preload['util.xml'] = (function (...)
					local _ENV = _ENV;
					local function module(name, ...)
						local t = package.loaded[name] or _ENV[name] or { _NAME = name };
						package.loaded[name] = t;
						for i = 1, select("#", ...) do
							(select(i, ...))(t);
						end
						_ENV = t;
						_M = t;
						return t;
					end
				
local st = require "util.stanza";
local lxp = require "lxp";

local _ENV = nil;

local parse_xml = (function()
	local ns_prefixes = {
		["http://www.w3.org/XML/1998/namespace"] = "xml";
	};
	local ns_separator = "\1";
	local ns_pattern = "^([^"..ns_separator.."]*)"..ns_separator.."?(.*)$";
	return function(xml)
		--luacheck: ignore 212/self
		local handler = {};
		local stanza = st.stanza("root");
		function handler:StartElement(tagname, attr)
			local curr_ns,name = tagname:match(ns_pattern);
			if name == "" then
				curr_ns, name = "", curr_ns;
			end
			if curr_ns ~= "" then
				attr.xmlns = curr_ns;
			end
			for i=1,#attr do
				local k = attr[i];
				attr[i] = nil;
				local ns, nm = k:match(ns_pattern);
				if nm ~= "" then
					ns = ns_prefixes[ns];
					if ns then
						attr[ns..":"..nm] = attr[k];
						attr[k] = nil;
					end
				end
			end
			stanza:tag(name, attr);
		end
		function handler:CharacterData(data)
			stanza:text(data);
		end
		function handler:EndElement()
			stanza:up();
		end
		local parser = lxp.new(handler, "\1");
		local ok, err, line, col = parser:parse(xml);
		if ok then ok, err, line, col = parser:parse(); end
		--parser:close();
		if ok then
			return stanza.tags[1];
		else
			return ok, err.." (line "..line..", col "..col..")";
		end
	end;
end)();

return {
	parse = parse_xml;
};
 end)
package.preload['util.rsm'] = (function (...)
					local _ENV = _ENV;
					local function module(name, ...)
						local t = package.loaded[name] or _ENV[name] or { _NAME = name };
						package.loaded[name] = t;
						for i = 1, select("#", ...) do
							(select(i, ...))(t);
						end
						_ENV = t;
						_M = t;
						return t;
					end
				local stanza = require"util.stanza".stanza;
local tostring, tonumber = tostring, tonumber;
local type = type;
local pairs = pairs;

local xmlns_rsm = 'http://jabber.org/protocol/rsm';

local element_parsers = {};

do
	local parsers = element_parsers;
	local function xs_int(st)
		return tonumber((st:get_text()));
	end
	local function xs_string(st)
		return st:get_text();
	end

	parsers.after = xs_string;
	parsers.before = function(st)
			local text = st:get_text();
			return text == "" or text;
		end;
	parsers.max = xs_int;
	parsers.index = xs_int;

	parsers.first = function(st)
			return { index = tonumber(st.attr.index); st:get_text() };
		end;
	parsers.last = xs_string;
	parsers.count = xs_int;
end

local element_generators = setmetatable({
	first = function(st, data)
		if type(data) == "table" then
			st:tag("first", { index = data.index }):text(data[1]):up();
		else
			st:tag("first"):text(tostring(data)):up();
		end
	end;
	before = function(st, data)
		if data == true then
			st:tag("before"):up();
		else
			st:tag("before"):text(tostring(data)):up();
		end
	end
}, {
	__index = function(_, name)
		return function(st, data)
			st:tag(name):text(tostring(data)):up();
		end
	end;
});


local function parse(set)
	local rs = {};
	for tag in set:childtags() do
		local name = tag.name;
		local parser = name and element_parsers[name];
		if parser then
			rs[name] = parser(tag);
		end
	end
	return rs;
end

local function generate(t)
	local st = stanza("set", { xmlns = xmlns_rsm });
	for k,v in pairs(t) do
		if element_parsers[k] then
			element_generators[k](st, v);
		end
	end
	return st;
end

local function get(st)
	local set = st:get_child("set", xmlns_rsm);
	if set and #set.tags > 0 then
		return parse(set);
	end
end

return { parse = parse, generate = generate, get = get };
 end)
package.preload['util.random'] = (function (...)
					local _ENV = _ENV;
					local function module(name, ...)
						local t = package.loaded[name] or _ENV[name] or { _NAME = name };
						package.loaded[name] = t;
						for i = 1, select("#", ...) do
							(select(i, ...))(t);
						end
						_ENV = t;
						_M = t;
						return t;
					end
				-- Prosody IM
-- Copyright (C) 2008-2014 Matthew Wild
-- Copyright (C) 2008-2014 Waqas Hussain
--
-- This project is MIT/X11 licensed. Please see the
-- COPYING file in the source package for more information.
--

local urandom = io.open("/dev/urandom", "r");

if urandom then
	return {
		seed = function () end;
		bytes = function (n) return urandom:read(n); end
	};
end

local crypto = require "crypto"
return crypto.rand;
 end)
package.preload['util.ip'] = (function (...)
					local _ENV = _ENV;
					local function module(name, ...)
						local t = package.loaded[name] or _ENV[name] or { _NAME = name };
						package.loaded[name] = t;
						for i = 1, select("#", ...) do
							(select(i, ...))(t);
						end
						_ENV = t;
						_M = t;
						return t;
					end
				-- Prosody IM
-- Copyright (C) 2008-2011 Florian Zeitz
--
-- This project is MIT/X11 licensed. Please see the
-- COPYING file in the source package for more information.
--

local ip_methods = {};
local ip_mt = { __index = function (ip, key) return (ip_methods[key])(ip); end,
		__tostring = function (ip) return ip.addr; end,
		__eq = function (ipA, ipB) return ipA.addr == ipB.addr; end};
local hex2bits = { ["0"] = "0000", ["1"] = "0001", ["2"] = "0010", ["3"] = "0011", ["4"] = "0100", ["5"] = "0101", ["6"] = "0110", ["7"] = "0111", ["8"] = "1000", ["9"] = "1001", ["A"] = "1010", ["B"] = "1011", ["C"] = "1100", ["D"] = "1101", ["E"] = "1110", ["F"] = "1111" };

local function new_ip(ipStr, proto)
	if not proto then
		local sep = ipStr:match("^%x+(.)");
		if sep == ":" or (not(sep) and ipStr:sub(1,1) == ":") then
			proto = "IPv6"
		elseif sep == "." then
			proto = "IPv4"
		end
		if not proto then
			return nil, "invalid address";
		end
	elseif proto ~= "IPv4" and proto ~= "IPv6" then
		return nil, "invalid protocol";
	end
	local zone;
	if proto == "IPv6" and ipStr:find('%', 1, true) then
		ipStr, zone = ipStr:match("^(.-)%%(.*)");
	end
	if proto == "IPv6" and ipStr:find('.', 1, true) then
		local changed;
		ipStr, changed = ipStr:gsub(":(%d+)%.(%d+)%.(%d+)%.(%d+)$", function(a,b,c,d)
			return (":%04X:%04X"):format(a*256+b,c*256+d);
		end);
		if changed ~= 1 then return nil, "invalid-address"; end
	end

	return setmetatable({ addr = ipStr, proto = proto, zone = zone }, ip_mt);
end

local function toBits(ip)
	local result = "";
	local fields = {};
	if ip.proto == "IPv4" then
		ip = ip.toV4mapped;
	end
	ip = (ip.addr):upper();
	ip:gsub("([^:]*):?", function (c) fields[#fields + 1] = c end);
	if not ip:match(":$") then fields[#fields] = nil; end
	for i, field in ipairs(fields) do
		if field:len() == 0 and i ~= 1 and i ~= #fields then
			for _ = 1, 16 * (9 - #fields) do
				result = result .. "0";
			end
		else
			for _ = 1, 4 - field:len() do
				result = result .. "0000";
			end
			for j = 1, field:len() do
				result = result .. hex2bits[field:sub(j, j)];
			end
		end
	end
	return result;
end

local function commonPrefixLength(ipA, ipB)
	ipA, ipB = toBits(ipA), toBits(ipB);
	for i = 1, 128 do
		if ipA:sub(i,i) ~= ipB:sub(i,i) then
			return i-1;
		end
	end
	return 128;
end

local function v4scope(ip)
	local fields = {};
	ip:gsub("([^.]*).?", function (c) fields[#fields + 1] = tonumber(c) end);
	-- Loopback:
	if fields[1] == 127 then
		return 0x2;
	-- Link-local unicast:
	elseif fields[1] == 169 and fields[2] == 254 then
		return 0x2;
	-- Global unicast:
	else
		return 0xE;
	end
end

local function v6scope(ip)
	-- Loopback:
	if ip:match("^[0:]*1$") then
		return 0x2;
	-- Link-local unicast:
	elseif ip:match("^[Ff][Ee][89ABab]") then
		return 0x2;
	-- Site-local unicast:
	elseif ip:match("^[Ff][Ee][CcDdEeFf]") then
		return 0x5;
	-- Multicast:
	elseif ip:match("^[Ff][Ff]") then
		return tonumber("0x"..ip:sub(4,4));
	-- Global unicast:
	else
		return 0xE;
	end
end

local function label(ip)
	if commonPrefixLength(ip, new_ip("::1", "IPv6")) == 128 then
		return 0;
	elseif commonPrefixLength(ip, new_ip("2002::", "IPv6")) >= 16 then
		return 2;
	elseif commonPrefixLength(ip, new_ip("2001::", "IPv6")) >= 32 then
		return 5;
	elseif commonPrefixLength(ip, new_ip("fc00::", "IPv6")) >= 7 then
		return 13;
	elseif commonPrefixLength(ip, new_ip("fec0::", "IPv6")) >= 10 then
		return 11;
	elseif commonPrefixLength(ip, new_ip("3ffe::", "IPv6")) >= 16 then
		return 12;
	elseif commonPrefixLength(ip, new_ip("::", "IPv6")) >= 96 then
		return 3;
	elseif commonPrefixLength(ip, new_ip("::ffff:0:0", "IPv6")) >= 96 then
		return 4;
	else
		return 1;
	end
end

local function precedence(ip)
	if commonPrefixLength(ip, new_ip("::1", "IPv6")) == 128 then
		return 50;
	elseif commonPrefixLength(ip, new_ip("2002::", "IPv6")) >= 16 then
		return 30;
	elseif commonPrefixLength(ip, new_ip("2001::", "IPv6")) >= 32 then
		return 5;
	elseif commonPrefixLength(ip, new_ip("fc00::", "IPv6")) >= 7 then
		return 3;
	elseif commonPrefixLength(ip, new_ip("fec0::", "IPv6")) >= 10 then
		return 1;
	elseif commonPrefixLength(ip, new_ip("3ffe::", "IPv6")) >= 16 then
		return 1;
	elseif commonPrefixLength(ip, new_ip("::", "IPv6")) >= 96 then
		return 1;
	elseif commonPrefixLength(ip, new_ip("::ffff:0:0", "IPv6")) >= 96 then
		return 35;
	else
		return 40;
	end
end

local function toV4mapped(ip)
	local fields = {};
	local ret = "::ffff:";
	ip:gsub("([^.]*).?", function (c) fields[#fields + 1] = tonumber(c) end);
	ret = ret .. ("%02x"):format(fields[1]);
	ret = ret .. ("%02x"):format(fields[2]);
	ret = ret .. ":"
	ret = ret .. ("%02x"):format(fields[3]);
	ret = ret .. ("%02x"):format(fields[4]);
	return new_ip(ret, "IPv6");
end

function ip_methods:toV4mapped()
	if self.proto ~= "IPv4" then return nil, "No IPv4 address" end
	local value = toV4mapped(self.addr);
	self.toV4mapped = value;
	return value;
end

function ip_methods:label()
	local value;
	if self.proto == "IPv4" then
		value = label(self.toV4mapped);
	else
		value = label(self);
	end
	self.label = value;
	return value;
end

function ip_methods:precedence()
	local value;
	if self.proto == "IPv4" then
		value = precedence(self.toV4mapped);
	else
		value = precedence(self);
	end
	self.precedence = value;
	return value;
end

function ip_methods:scope()
	local value;
	if self.proto == "IPv4" then
		value = v4scope(self.addr);
	else
		value = v6scope(self.addr);
	end
	self.scope = value;
	return value;
end

function ip_methods:private()
	local private = self.scope ~= 0xE;
	if not private and self.proto == "IPv4" then
		local ip = self.addr;
		local fields = {};
		ip:gsub("([^.]*).?", function (c) fields[#fields + 1] = tonumber(c) end);
		if fields[1] == 127 or fields[1] == 10 or (fields[1] == 192 and fields[2] == 168)
		or (fields[1] == 172 and (fields[2] >= 16 or fields[2] <= 32)) then
			private = true;
		end
	end
	self.private = private;
	return private;
end

local function parse_cidr(cidr)
	local bits;
	local ip_len = cidr:find("/", 1, true);
	if ip_len then
		bits = tonumber(cidr:sub(ip_len+1, -1));
		cidr = cidr:sub(1, ip_len-1);
	end
	return new_ip(cidr), bits;
end

local function match(ipA, ipB, bits)
	local common_bits = commonPrefixLength(ipA, ipB);
	if bits and ipB.proto == "IPv4" then
		common_bits = common_bits - 96; -- v6 mapped addresses always share these bits
	end
	return common_bits >= (bits or 128);
end

return {new_ip = new_ip,
	commonPrefixLength = commonPrefixLength,
	parse_cidr = parse_cidr,
	match=match};
 end)
package.preload['util.time'] = (function (...)
					local _ENV = _ENV;
					local function module(name, ...)
						local t = package.loaded[name] or _ENV[name] or { _NAME = name };
						package.loaded[name] = t;
						for i = 1, select("#", ...) do
							(select(i, ...))(t);
						end
						_ENV = t;
						_M = t;
						return t;
					end
				-- Import gettime() from LuaSocket, as a way to access high-resolution time
-- in a platform-independent way

local socket_gettime = require "socket".gettime;

return {
	now = socket_gettime;
}
 end)
package.preload['util.sasl.scram'] = (function (...)
					local _ENV = _ENV;
					local function module(name, ...)
						local t = package.loaded[name] or _ENV[name] or { _NAME = name };
						package.loaded[name] = t;
						for i = 1, select("#", ...) do
							(select(i, ...))(t);
						end
						_ENV = t;
						_M = t;
						return t;
					end
				
local base64, unbase64 = require "mime".b64, require"mime".unb64;
local hashes = require"util.hashes";
local bit = require"bit";
local random = require"util.random";

local tonumber = tonumber;
local char, byte = string.char, string.byte;
local gsub = string.gsub;
local xor = bit.bxor;

local function XOR(a, b)
	return (gsub(a, "()(.)", function(i, c)
		return char(xor(byte(c), byte(b, i)))
	end));
end

local H, HMAC = hashes.sha1, hashes.hmac_sha1;

local function Hi(str, salt, i)
	local U = HMAC(str, salt .. "\0\0\0\1");
	local ret = U;
	for _ = 2, i do
		U = HMAC(str, U);
		ret = XOR(ret, U);
	end
	return ret;
end

local function Normalize(str)
	return str; -- TODO
end

local function value_safe(str)
	return (gsub(str, "[,=]", { [","] = "=2C", ["="] = "=3D" }));
end

local function scram(stream, name)
	local username = "n=" .. value_safe(stream.username);
	local c_nonce = base64(random.bytes(15));
	local our_nonce = "r=" .. c_nonce;
	local client_first_message_bare = username .. "," .. our_nonce;
	local cbind_data = "";
	local gs2_cbind_flag = stream.conn:ssl() and "y" or "n";
	if name == "SCRAM-SHA-1-PLUS" then
		cbind_data = stream.conn:socket():getfinished();
		gs2_cbind_flag = "p=tls-unique";
	end
	local gs2_header = gs2_cbind_flag .. ",,";
	local client_first_message = gs2_header .. client_first_message_bare;
	local cont, server_first_message = coroutine.yield(client_first_message);
	if cont ~= "challenge" then return false end

	local nonce, salt, iteration_count = server_first_message:match("(r=[^,]+),s=([^,]*),i=(%d+)");
	local i = tonumber(iteration_count);
	salt = unbase64(salt);
	if not nonce or not salt or not i then
		return false, "Could not parse server_first_message";
	elseif nonce:find(c_nonce, 3, true) ~= 3 then
		return false, "nonce sent by server does not match our nonce";
	elseif nonce == our_nonce then
		return false, "server did not append s-nonce to nonce";
	end

	local cbind_input = gs2_header .. cbind_data;
	local channel_binding = "c=" .. base64(cbind_input);
	local client_final_message_without_proof = channel_binding .. "," .. nonce;

	local SaltedPassword;
	local ClientKey;
	local ServerKey;

	if stream.client_key and stream.server_key then
		ClientKey = stream.client_key;
		ServerKey = stream.server_key;
	else
		if stream.salted_password then
			SaltedPassword = stream.salted_password;
		elseif stream.password then
			SaltedPassword = Hi(Normalize(stream.password), salt, i);
		end
		ServerKey = HMAC(SaltedPassword, "Server Key");
		ClientKey = HMAC(SaltedPassword, "Client Key");
	end

	local StoredKey       = H(ClientKey);
	local AuthMessage     = client_first_message_bare .. "," ..  server_first_message .. "," ..  client_final_message_without_proof;
	local ClientSignature = HMAC(StoredKey, AuthMessage);
	local ClientProof     = XOR(ClientKey, ClientSignature);
	local ServerSignature = HMAC(ServerKey, AuthMessage);

	local proof = "p=" .. base64(ClientProof);
	local client_final_message = client_final_message_without_proof .. "," .. proof;

	local ok, server_final_message = coroutine.yield(client_final_message);
	if ok ~= "success" then return false, "success-expected" end

	local verifier = server_final_message:match("v=([^,]+)");
	if unbase64(verifier) ~= ServerSignature then
		return false, "server signature did not match";
	end
	return true;
end

return function (stream, name)
	if stream.username and (stream.password or (stream.client_key or stream.server_key)) then
		if name == "SCRAM-SHA-1" then
			return scram, 99;
		elseif name == "SCRAM-SHA-1-PLUS" then
			local sock = stream.conn:ssl() and stream.conn:socket();
			if sock and sock.getfinished then
				return scram, 100;
			end
		end
	end
end

 end)
package.preload['util.sasl.plain'] = (function (...)
					local _ENV = _ENV;
					local function module(name, ...)
						local t = package.loaded[name] or _ENV[name] or { _NAME = name };
						package.loaded[name] = t;
						for i = 1, select("#", ...) do
							(select(i, ...))(t);
						end
						_ENV = t;
						_M = t;
						return t;
					end
				
return function (stream, name)
	if name == "PLAIN" and stream.username and stream.password then
		return function (stream)
			return "success" == coroutine.yield("\0"..stream.username.."\0"..stream.password);
		end, 5;
	end
end

 end)
package.preload['util.sasl.anonymous'] = (function (...)
					local _ENV = _ENV;
					local function module(name, ...)
						local t = package.loaded[name] or _ENV[name] or { _NAME = name };
						package.loaded[name] = t;
						for i = 1, select("#", ...) do
							(select(i, ...))(t);
						end
						_ENV = t;
						_M = t;
						return t;
					end
				
return function (stream, name)
	if name == "ANONYMOUS" then
		return function ()
			return coroutine.yield() == "success";
		end, 0;
	end
end
 end)
package.preload['verse.plugins.tls'] = (function (...)
					local _ENV = _ENV;
					local function module(name, ...)
						local t = package.loaded[name] or _ENV[name] or { _NAME = name };
						package.loaded[name] = t;
						for i = 1, select("#", ...) do
							(select(i, ...))(t);
						end
						_ENV = t;
						_M = t;
						return t;
					end
				local verse = require "verse";

local xmlns_tls = "urn:ietf:params:xml:ns:xmpp-tls";

function verse.plugins.tls(stream)
	local function handle_features(features_stanza)
		if stream.authenticated then return; end
		if features_stanza:get_child("starttls", xmlns_tls) and stream.conn.starttls then
			stream:debug("Negotiating TLS...");
			stream:send(verse.stanza("starttls", { xmlns = xmlns_tls }));
			return true;
		elseif not stream.conn.starttls and not stream.secure then
			stream:warn("SSL library (LuaSec) not loaded, so TLS not available");
		elseif not stream.secure then
			stream:debug("Server doesn't offer TLS :(");
		end
	end
	local function handle_tls(tls_status)
		if tls_status.name == "proceed" then
			stream:debug("Server says proceed, handshake starting...");
			stream.conn:starttls(stream.ssl or {mode="client", protocol="sslv23", options="no_sslv2",capath="/etc/ssl/certs"}, true);
		end
	end
	local function handle_status(new_status)
		if new_status == "ssl-handshake-complete" then
			stream.secure = true;
			stream:debug("Re-opening stream...");
			stream:reopen();
		end
	end
	stream:hook("stream-features", handle_features, 400);
	stream:hook("stream/"..xmlns_tls, handle_tls);
	stream:hook("status", handle_status, 400);

	return true;
end
 end)
package.preload['verse.plugins.sasl'] = (function (...)
					local _ENV = _ENV;
					local function module(name, ...)
						local t = package.loaded[name] or _ENV[name] or { _NAME = name };
						package.loaded[name] = t;
						for i = 1, select("#", ...) do
							(select(i, ...))(t);
						end
						_ENV = t;
						_M = t;
						return t;
					end
				local verse = require"verse";
local base64, unbase64 = require "mime".b64, require"mime".unb64;
local xmlns_sasl = "urn:ietf:params:xml:ns:xmpp-sasl";

function verse.plugins.sasl(stream)
	local function handle_features(features_stanza)
		if stream.authenticated then return; end
		stream:debug("Authenticating with SASL...");
		local sasl_mechanisms = features_stanza:get_child("mechanisms", xmlns_sasl);
		if not sasl_mechanisms then return end

		local mechanisms = {};
		local preference = {};

		for mech in sasl_mechanisms:childtags("mechanism") do
			mech = mech:get_text();
			stream:debug("Server offers %s", mech);
			if not mechanisms[mech] then
				local name = mech:match("[^-]+");
				local ok, impl = pcall(require, "util.sasl."..name:lower());
				if ok then
					stream:debug("Loaded SASL %s module", name);
					mechanisms[mech], preference[mech] = impl(stream, mech);
				elseif not tostring(impl):match("not found") then
					stream:debug("Loading failed: %s", tostring(impl));
				end
			end
		end

		local supported = {}; -- by the server
		for mech in pairs(mechanisms) do
			table.insert(supported, mech);
		end
		if not supported[1] then
			stream:event("authentication-failure", { condition = "no-supported-sasl-mechanisms" });
			stream:close();
			return;
		end
		table.sort(supported, function (a, b) return preference[a] > preference[b]; end);
		local mechanism, initial_data = supported[1];
		stream:debug("Selecting %s mechanism...", mechanism);
		stream.sasl_mechanism = coroutine.wrap(mechanisms[mechanism]);
		initial_data = stream:sasl_mechanism(mechanism);
		local auth_stanza = verse.stanza("auth", { xmlns = xmlns_sasl, mechanism = mechanism });
		if initial_data then
			auth_stanza:text(base64(initial_data));
		end
		stream:send(auth_stanza);
		return true;
	end

	local function handle_sasl(sasl_stanza)
		if sasl_stanza.name == "failure" then
			local err = sasl_stanza.tags[1];
			local text = sasl_stanza:get_child_text("text");
			stream:event("authentication-failure", { condition = err.name, text = text });
			stream:close();
			return false;
		end
		local ok, err = stream.sasl_mechanism(sasl_stanza.name, unbase64(sasl_stanza:get_text()));
		if not ok then
			stream:event("authentication-failure", { condition = err });
			stream:close();
			return false;
		elseif ok == true then
			stream:event("authentication-success");
			stream.authenticated = true
			stream:reopen();
		else
			stream:send(verse.stanza("response", { xmlns = xmlns_sasl }):text(base64(ok)));
		end
		return true;
	end

	stream:hook("stream-features", handle_features, 300);
	stream:hook("stream/"..xmlns_sasl, handle_sasl);

	return true;
end

 end)
package.preload['verse.plugins.bind'] = (function (...)
					local _ENV = _ENV;
					local function module(name, ...)
						local t = package.loaded[name] or _ENV[name] or { _NAME = name };
						package.loaded[name] = t;
						for i = 1, select("#", ...) do
							(select(i, ...))(t);
						end
						_ENV = t;
						_M = t;
						return t;
					end
				local verse = require "verse";
local jid = require "util.jid";

local xmlns_bind = "urn:ietf:params:xml:ns:xmpp-bind";

function verse.plugins.bind(stream)
	local function handle_features(features)
		if stream.bound then return; end
		stream:debug("Binding resource...");
		stream:send_iq(verse.iq({ type = "set" }):tag("bind", {xmlns=xmlns_bind}):tag("resource"):text(stream.resource),
			function (reply)
				if reply.attr.type == "result" then
					local result_jid = reply
						:get_child("bind", xmlns_bind)
							:get_child_text("jid");
					stream.username, stream.host, stream.resource = jid.split(result_jid);
					stream.jid, stream.bound = result_jid, true;
					stream:event("bind-success", { jid = result_jid });
				elseif reply.attr.type == "error" then
					local err = reply:child_with_name("error");
					local type, condition, text = reply:get_error();
					stream:event("bind-failure", { error = condition, text = text, type = type });
				end
			end);
	end
	stream:hook("stream-features", handle_features, 200);
	return true;
end
 end)
package.preload['verse.plugins.session'] = (function (...)
					local _ENV = _ENV;
					local function module(name, ...)
						local t = package.loaded[name] or _ENV[name] or { _NAME = name };
						package.loaded[name] = t;
						for i = 1, select("#", ...) do
							(select(i, ...))(t);
						end
						_ENV = t;
						_M = t;
						return t;
					end
				local verse = require "verse";

local xmlns_session = "urn:ietf:params:xml:ns:xmpp-session";

function verse.plugins.session(stream)

	local function handle_features(features)
		local session_feature = features:get_child("session", xmlns_session);
		if session_feature and not session_feature:get_child("optional") then
			local function handle_binding(jid)
				stream:debug("Establishing Session...");
				stream:send_iq(verse.iq({ type = "set" }):tag("session", {xmlns=xmlns_session}),
					function (reply)
						if reply.attr.type == "result" then
							stream:event("session-success");
						elseif reply.attr.type == "error" then
							local type, condition, text = reply:get_error();
							stream:event("session-failure", { error = condition, text = text, type = type });
						end
					end);
				return true;
			end
			stream:hook("bind-success", handle_binding);
		end
	end
	stream:hook("stream-features", handle_features);

	return true;
end
 end)
package.preload['verse.plugins.legacy'] = (function (...)
					local _ENV = _ENV;
					local function module(name, ...)
						local t = package.loaded[name] or _ENV[name] or { _NAME = name };
						package.loaded[name] = t;
						for i = 1, select("#", ...) do
							(select(i, ...))(t);
						end
						_ENV = t;
						_M = t;
						return t;
					end
				local verse = require "verse";
local uuid = require "util.uuid".generate;

local xmlns_auth = "jabber:iq:auth";

function verse.plugins.legacy(stream)
	local function handle_auth_form(result)
		local query = result:get_child("query", xmlns_auth);
		if result.attr.type ~= "result" or not query then
			local type, cond, text = result:get_error();
                       stream:debug("warn", "%s %s: %s", type, cond, text);
                       --stream:event("authentication-failure", { condition = cond });
                       -- COMPAT continue anyways
		end
		local auth_data = {
			username = stream.username;
			password = stream.password;
			resource = stream.resource or uuid();
			digest = false, sequence = false, token = false;
		};
		local request = verse.iq({ to = stream.host, type = "set" })
			:tag("query", { xmlns = xmlns_auth });
               if #query > 0 then
		for tag in query:childtags() do
			local field = tag.name;
			local value = auth_data[field];
			if value then
				request:tag(field):text(auth_data[field]):up();
			elseif value == nil then
				local cond = "feature-not-implemented";
				stream:event("authentication-failure", { condition = cond });
				return false;
			end
		end
               else -- COMPAT for servers not following XEP 78
                       for field, value in pairs(auth_data) do
                               if value then
                                       request:tag(field):text(value):up();
                               end
                       end
               end
		stream:send_iq(request, function (response)
			if response.attr.type == "result" then
				stream.resource = auth_data.resource;
				stream.jid = auth_data.username.."@"..stream.host.."/"..auth_data.resource;
				stream:event("authentication-success");
				stream:event("bind-success", stream.jid);
			else
				local type, cond, text = response:get_error();
				stream:event("authentication-failure", { condition = cond });
			end
		end);
	end

	local function handle_opened(attr)
		if not attr.version then
			stream:send_iq(verse.iq({type="get"})
				:tag("query", { xmlns = "jabber:iq:auth" })
					:tag("username"):text(stream.username),
				handle_auth_form);
		end
	end
	stream:hook("opened", handle_opened);
end
 end)
package.preload['verse.plugins.compression'] = (function (...)
					local _ENV = _ENV;
					local function module(name, ...)
						local t = package.loaded[name] or _ENV[name] or { _NAME = name };
						package.loaded[name] = t;
						for i = 1, select("#", ...) do
							(select(i, ...))(t);
						end
						_ENV = t;
						_M = t;
						return t;
					end
				-- Copyright (C) 2009-2010 Matthew Wild
-- Copyright (C) 2009-2010 Tobias Markmann
--
-- This project is MIT/X11 licensed. Please see the
-- COPYING file in the source package for more information.
--

local verse = require "verse";
local zlib = require "zlib";

local xmlns_compression_feature = "http://jabber.org/features/compress"
local xmlns_compression_protocol = "http://jabber.org/protocol/compress"
local xmlns_stream = "http://etherx.jabber.org/streams";

local compression_level = 9;

-- returns either nil or a fully functional ready to use inflate stream
local function get_deflate_stream(session)
	local status, deflate_stream = pcall(zlib.deflate, compression_level);
	if status == false then
		local error_st = verse.stanza("failure", {xmlns=xmlns_compression_protocol}):tag("setup-failed");
		session:send(error_st);
		session:error("Failed to create zlib.deflate filter: %s", tostring(deflate_stream));
		return
	end
	return deflate_stream
end

-- returns either nil or a fully functional ready to use inflate stream
local function get_inflate_stream(session)
	local status, inflate_stream = pcall(zlib.inflate);
	if status == false then
		local error_st = verse.stanza("failure", {xmlns=xmlns_compression_protocol}):tag("setup-failed");
		session:send(error_st);
		session:error("Failed to create zlib.inflate filter: %s", tostring(inflate_stream));
		return
	end
	return inflate_stream
end

-- setup compression for a stream
local function setup_compression(session, deflate_stream)
	function session:send(t)
			--TODO: Better code injection in the sending process
			local status, compressed, eof = pcall(deflate_stream, tostring(t), 'sync');
			if status == false then
				session:close({
					condition = "undefined-condition";
					text = compressed;
					extra = verse.stanza("failure", {xmlns=xmlns_compression_protocol}):tag("processing-failed");
				});
				session:warn("Compressed send failed: %s", tostring(compressed));
				return;
			end
			session.conn:write(compressed);
		end;
end

-- setup decompression for a stream
local function setup_decompression(session, inflate_stream)
	local old_data = session.data
	session.data = function(conn, data)
			session:debug("Decompressing data...");
			local status, decompressed, eof = pcall(inflate_stream, data);
			if status == false then
				session:close({
					condition = "undefined-condition";
					text = decompressed;
					extra = verse.stanza("failure", {xmlns=xmlns_compression_protocol}):tag("processing-failed");
				});
				stream:warn("%s", tostring(decompressed));
				return;
			end
			return old_data(conn, decompressed);
		end;
end

function verse.plugins.compression(stream)
	local function handle_features(features)
		if not stream.compressed then
			-- does remote server support compression?
			local comp_st = features:child_with_name("compression");
			if comp_st then
				-- do we support the mechanism
				for a in comp_st:children() do
					local algorithm = a[1]
					if algorithm == "zlib" then
						stream:send(verse.stanza("compress", {xmlns=xmlns_compression_protocol}):tag("method"):text("zlib"))
						stream:debug("Enabled compression using zlib.")
						return true;
					end
				end
				session:debug("Remote server supports no compression algorithm we support.")
			end
		end
	end
	local function handle_compressed(stanza)
		if stanza.name == "compressed" then
			stream:debug("Activating compression...")

			-- create deflate and inflate streams
			local deflate_stream = get_deflate_stream(stream);
			if not deflate_stream then return end

			local inflate_stream = get_inflate_stream(stream);
			if not inflate_stream then return end

			-- setup compression for stream.w
			setup_compression(stream, deflate_stream);

			-- setup decompression for stream.data
			setup_decompression(stream, inflate_stream);

			stream.compressed = true;
			stream:reopen();
		elseif stanza.name == "failure" then
			stream:warn("Failed to establish compression");
		end
	end
	stream:hook("stream-features", handle_features, 250);
	stream:hook("stream/"..xmlns_compression_protocol, handle_compressed);
end
 end)
package.preload['verse.plugins.smacks'] = (function (...)
					local _ENV = _ENV;
					local function module(name, ...)
						local t = package.loaded[name] or _ENV[name] or { _NAME = name };
						package.loaded[name] = t;
						for i = 1, select("#", ...) do
							(select(i, ...))(t);
						end
						_ENV = t;
						_M = t;
						return t;
					end
				local verse = require "verse";
local now = require"socket".gettime;

local xmlns_sm = "urn:xmpp:sm:3";

function verse.plugins.smacks(stream)
	-- State for outgoing stanzas
	local outgoing_queue = {};
	local last_ack = 0;
	local last_stanza_time = now();
	local timer_active;

	-- State for incoming stanzas
	local handled_stanza_count = 0;

	-- Catch incoming stanzas
	local function incoming_stanza(stanza)
		if stanza.attr.xmlns == "jabber:client" or not stanza.attr.xmlns then
			handled_stanza_count = handled_stanza_count + 1;
			stream:debug("Increasing handled stanzas to %d for %s", handled_stanza_count, stanza:top_tag());
		end
	end

	-- Catch outgoing stanzas
	local function outgoing_stanza(stanza)
		-- NOTE: This will not behave nice if stanzas are serialized before this point
		if stanza.name and not stanza.attr.xmlns then
			-- serialize stanzas in order to bypass this on resumption
			outgoing_queue[#outgoing_queue+1] = tostring(stanza);
			last_stanza_time = now();
			if not timer_active then
				timer_active = true;
				stream:debug("Waiting to send ack request...");
				verse.add_task(1, function()
					if #outgoing_queue == 0 then
						timer_active = false;
						return;
					end
					local time_since_last_stanza = now() - last_stanza_time;
					if time_since_last_stanza < 1 and #outgoing_queue < 10 then
						return 1 - time_since_last_stanza;
					end
					stream:debug("Time up, sending <r>...");
					timer_active = false;
					stream:send(verse.stanza("r", { xmlns = xmlns_sm }));
				end);
			end
		end
	end

	local function on_disconnect()
		stream:debug("smacks: connection lost");
		stream.stream_management_supported = nil;
		if stream.resumption_token then
			stream:debug("smacks: have resumption token, reconnecting in 1s...");
			stream.authenticated = nil;
			verse.add_task(1, function ()
				stream:connect(stream.connect_host or stream.host, stream.connect_port or 5222);
			end);
			return true;
		end
	end

	-- Graceful shutdown
	local function on_close()
		stream.resumption_token = nil;
		stream:unhook("disconnected", on_disconnect);
	end

	local function handle_sm_command(stanza)
		if stanza.name == "r" then -- Request for acks for stanzas we received
			stream:debug("Ack requested... acking %d handled stanzas", handled_stanza_count);
			stream:send(verse.stanza("a", { xmlns = xmlns_sm, h = tostring(handled_stanza_count) }));
		elseif stanza.name == "a" then -- Ack for stanzas we sent
			local new_ack = tonumber(stanza.attr.h);
			if new_ack > last_ack then
				local old_unacked = #outgoing_queue;
				for i=last_ack+1,new_ack do
					table.remove(outgoing_queue, 1);
				end
				stream:debug("Received ack: New ack: "..new_ack.." Last ack: "..last_ack.." Unacked stanzas now: "..#outgoing_queue.." (was "..old_unacked..")");
				last_ack = new_ack;
			else
				stream:warn("Received bad ack for "..new_ack.." when last ack was "..last_ack);
			end
		elseif stanza.name == "enabled" then

			if stanza.attr.id then
				stream.resumption_token = stanza.attr.id;
				stream:hook("closed", on_close, 100);
				stream:hook("disconnected", on_disconnect, 100);
			end
		elseif stanza.name == "resumed" then
			local new_ack = tonumber(stanza.attr.h);
			if new_ack > last_ack then
				local old_unacked = #outgoing_queue;
				for i=last_ack+1,new_ack do
					table.remove(outgoing_queue, 1);
				end
				stream:debug("Received ack: New ack: "..new_ack.." Last ack: "..last_ack.." Unacked stanzas now: "..#outgoing_queue.." (was "..old_unacked..")");
				last_ack = new_ack;
			end
			for i=1,#outgoing_queue do
				stream:send(outgoing_queue[i]);
			end
			outgoing_queue = {};
			stream:debug("Resumed successfully");
			stream:event("resumed");
		else
			stream:warn("Don't know how to handle "..xmlns_sm.."/"..stanza.name);
		end
	end

	local function on_bind_success()
		if not stream.smacks then
			--stream:unhook("bind-success", on_bind_success);
			stream:debug("smacks: sending enable");
			stream:send(verse.stanza("enable", { xmlns = xmlns_sm, resume = "true" }));
			stream.smacks = true;

			-- Catch stanzas
			stream:hook("stanza", incoming_stanza);
			stream:hook("outgoing", outgoing_stanza);
		end
	end

	local function on_features(features)
		if features:get_child("sm", xmlns_sm) then
			stream.stream_management_supported = true;
			if stream.smacks and stream.bound then -- Already enabled in a previous session - resume
				stream:debug("Resuming stream with %d handled stanzas", handled_stanza_count);
				stream:send(verse.stanza("resume", { xmlns = xmlns_sm,
					h = handled_stanza_count, previd = stream.resumption_token }));
				return true;
			else
				stream:hook("bind-success", on_bind_success, 1);
			end
		end
	end

	stream:hook("stream-features", on_features, 250);
	stream:hook("stream/"..xmlns_sm, handle_sm_command);
	--stream:hook("ready", on_stream_ready, 500);
end
 end)
package.preload['verse.plugins.keepalive'] = (function (...)
					local _ENV = _ENV;
					local function module(name, ...)
						local t = package.loaded[name] or _ENV[name] or { _NAME = name };
						package.loaded[name] = t;
						for i = 1, select("#", ...) do
							(select(i, ...))(t);
						end
						_ENV = t;
						_M = t;
						return t;
					end
				local verse = require "verse";

function verse.plugins.keepalive(stream)
	stream.keepalive_timeout = stream.keepalive_timeout or 300;
	verse.add_task(stream.keepalive_timeout, function ()
		stream.conn:write(" ");
		return stream.keepalive_timeout;
	end);
end
 end)
package.preload['verse.plugins.disco'] = (function (...)
					local _ENV = _ENV;
					local function module(name, ...)
						local t = package.loaded[name] or _ENV[name] or { _NAME = name };
						package.loaded[name] = t;
						for i = 1, select("#", ...) do
							(select(i, ...))(t);
						end
						_ENV = t;
						_M = t;
						return t;
					end
				-- Verse XMPP Library
-- Copyright (C) 2010 Hubert Chathi <hubert@uhoreg.ca>
-- Copyright (C) 2010 Matthew Wild <mwild1@gmail.com>
--
-- This project is MIT/X11 licensed. Please see the
-- COPYING file in the source package for more information.
--

local verse = require "verse";
local b64 = require("mime").b64;
local sha1 = require("util.hashes").sha1;
local calculate_hash = require "util.caps".calculate_hash;

local xmlns_caps = "http://jabber.org/protocol/caps";
local xmlns_disco = "http://jabber.org/protocol/disco";
local xmlns_disco_info = xmlns_disco.."#info";
local xmlns_disco_items = xmlns_disco.."#items";

function verse.plugins.disco(stream)
	stream:add_plugin("presence");
	local disco_info_mt = {
		__index = function(t, k)
			local node = { identities = {}, features = {} };
			if k == "identities" or k == "features" then
				return t[false][k]
			end
			t[k] = node;
			return node;
		end,
	};
	local disco_items_mt = {
		__index = function(t, k)
			local node = { };
			t[k] = node;
			return node;
		end,
	};
	stream.disco = {
		cache = {},
		info = setmetatable({
			[false] = {
				identities = {
					{category = 'client', type='pc', name='Verse'},
				},
				features = {
					[xmlns_caps] = true,
					[xmlns_disco_info] = true,
					[xmlns_disco_items] = true,
				},
			},
		}, disco_info_mt);
		items = setmetatable({[false]={}}, disco_items_mt);
	};

	stream.caps = {}
	stream.caps.node = 'http://code.matthewwild.co.uk/verse/'

	local function build_self_disco_info_stanza(query_node)
		local node = stream.disco.info[query_node or false];
		if query_node and query_node == stream.caps.node .. "#" .. stream.caps.hash then
			node = stream.disco.info[false];
		end
		local identities, features = node.identities, node.features

		-- construct the response
		local result = verse.stanza("query", {
			xmlns = xmlns_disco_info,
			node = query_node,
		});
		for _,identity in pairs(identities) do
			result:tag('identity', identity):up()
		end
		for feature in pairs(features) do
			result:tag('feature', { var = feature }):up()
		end
		return result;
	end

	setmetatable(stream.caps, {
		__call = function (...) -- vararg: allow calling as function or member
			-- retrieve the c stanza to insert into the
			-- presence stanza
			local hash = calculate_hash(build_self_disco_info_stanza())
			stream.caps.hash = hash;
			-- TODO proper caching.... some day
			return verse.stanza('c', {
				xmlns = xmlns_caps,
				hash = 'sha-1',
				node = stream.caps.node,
				ver = hash
			})
		end
	})

	function stream:set_identity(identity, node)
		self.disco.info[node or false].identities = { identity };
		stream:resend_presence();
	end

	function stream:add_identity(identity, node)
		local identities = self.disco.info[node or false].identities;
		identities[#identities + 1] = identity;
		stream:resend_presence();
	end

	function stream:add_disco_feature(feature, node)
		local feature = feature.var or feature;
		self.disco.info[node or false].features[feature] = true;
		stream:resend_presence();
	end

	function stream:remove_disco_feature(feature, node)
		local feature = feature.var or feature;
		self.disco.info[node or false].features[feature] = nil;
		stream:resend_presence();
	end

	function stream:add_disco_item(item, node)
		local items = self.disco.items[node or false];
		items[#items +1] = item;
	end

	function stream:remove_disco_item(item, node)
		local items = self.disco.items[node or false];
		for i=#items,1,-1 do
			if items[i] == item then
				table.remove(items, i);
			end
		end
	end

	-- TODO Node?
	function stream:jid_has_identity(jid, category, type)
		local cached_disco = self.disco.cache[jid];
		if not cached_disco then
			return nil, "no-cache";
		end
		local identities = self.disco.cache[jid].identities;
		if type then
			return identities[category.."/"..type] or false;
		end
		-- Check whether we have any identities with this category instead
		for identity in pairs(identities) do
			if identity:match("^(.*)/") == category then
				return true;
			end
		end
	end

	function stream:jid_supports(jid, feature)
		local cached_disco = self.disco.cache[jid];
		if not cached_disco or not cached_disco.features then
			return nil, "no-cache";
		end
		return cached_disco.features[feature] or false;
	end

	function stream:get_local_services(category, type)
		local host_disco = self.disco.cache[self.host];
		if not(host_disco) or not(host_disco.items) then
			return nil, "no-cache";
		end

		local results = {};
		for _, service in ipairs(host_disco.items) do
			if self:jid_has_identity(service.jid, category, type) then
				table.insert(results, service.jid);
			end
		end
		return results;
	end

	function stream:disco_local_services(callback)
		self:disco_items(self.host, nil, function (items)
			if not items then
				return callback({});
			end
			local n_items = 0;
			local function item_callback()
				n_items = n_items - 1;
				if n_items == 0 then
					return callback(items);
				end
			end

			for _, item in ipairs(items) do
				if item.jid then
					n_items = n_items + 1;
					self:disco_info(item.jid, nil, item_callback);
				end
			end
			if n_items == 0 then
				return callback(items);
			end
		end);
	end

	function stream:disco_info(jid, node, callback)
		local disco_request = verse.iq({ to = jid, type = "get" })
			:tag("query", { xmlns = xmlns_disco_info, node = node });
		self:send_iq(disco_request, function (result)
			if result.attr.type == "error" then
				return callback(nil, result:get_error());
			end

			local identities, features = {}, {};

			for tag in result:get_child("query", xmlns_disco_info):childtags() do
				if tag.name == "identity" then
					identities[tag.attr.category.."/"..tag.attr.type] = tag.attr.name or true;
				elseif tag.name == "feature" then
					features[tag.attr.var] = true;
				end
			end


			if not self.disco.cache[jid] then
				self.disco.cache[jid] = { nodes = {} };
			end

			if node then
				if not self.disco.cache[jid].nodes[node] then
					self.disco.cache[jid].nodes[node] = { nodes = {} };
				end
				self.disco.cache[jid].nodes[node].identities = identities;
				self.disco.cache[jid].nodes[node].features = features;
			else
				self.disco.cache[jid].identities = identities;
				self.disco.cache[jid].features = features;
			end
			return callback(self.disco.cache[jid]);
		end);
	end

	function stream:disco_items(jid, node, callback)
		local disco_request = verse.iq({ to = jid, type = "get" })
			:tag("query", { xmlns = xmlns_disco_items, node = node });
		self:send_iq(disco_request, function (result)
			if result.attr.type == "error" then
				return callback(nil, result:get_error());
			end
			local disco_items = { };
			for tag in result:get_child("query", xmlns_disco_items):childtags() do
				if tag.name == "item" then
					table.insert(disco_items, {
						name = tag.attr.name;
						jid = tag.attr.jid;
						node = tag.attr.node;
					});
				end
			end

			if not self.disco.cache[jid] then
				self.disco.cache[jid] = { nodes = {} };
			end

			if node then
				if not self.disco.cache[jid].nodes[node] then
					self.disco.cache[jid].nodes[node] = { nodes = {} };
				end
				self.disco.cache[jid].nodes[node].items = disco_items;
			else
				self.disco.cache[jid].items = disco_items;
			end
			return callback(disco_items);
		end);
	end

	stream:hook("iq/"..xmlns_disco_info, function (stanza)
		local query = stanza.tags[1];
		if stanza.attr.type == 'get' and query.name == "query" then
			local query_tag = build_self_disco_info_stanza(query.attr.node);
			local result = verse.reply(stanza):add_child(query_tag);
			stream:send(result);
			return true
		end
	end);

	stream:hook("iq/"..xmlns_disco_items, function (stanza)
		local query = stanza.tags[1];
		if stanza.attr.type == 'get' and query.name == "query" then
			-- figure out what items to send
			local items = stream.disco.items[query.attr.node or false];

			-- construct the response
			local result = verse.reply(stanza):tag('query',{
				xmlns = xmlns_disco_items,
				node = query.attr.node
			})
			for i=1,#items do
				result:tag('item', items[i]):up()
			end
			stream:send(result);
			return true
		end
	end);

	local initial_disco_started;
	stream:hook("ready", function ()
		if initial_disco_started then return; end
		initial_disco_started = true;

		-- Using the disco cache, fires events for each identity of a given JID
		local function scan_identities_for_service(service_jid)
			local service_disco_info = stream.disco.cache[service_jid];
			if service_disco_info then
				for identity in pairs(service_disco_info.identities) do
					local category, type = identity:match("^(.*)/(.*)$");
					print(service_jid, category, type)
					stream:event("disco/service-discovered/"..category, {
						type = type, jid = service_jid;
					});
				end
			end
		end

		stream:disco_info(stream.host, nil, function ()
			scan_identities_for_service(stream.host);
		end);

		stream:disco_local_services(function (services)
			for _, service in ipairs(services) do
				scan_identities_for_service(service.jid);
			end
			stream:event("ready");
		end);
		return true;
	end, 50);

	stream:hook("presence-out", function (presence)
		presence:remove_children("c", xmlns_caps);
		presence:reset():add_child(stream:caps()):reset();
	end, 10);
end

-- end of disco.lua
 end)
package.preload['verse.plugins.version'] = (function (...)
					local _ENV = _ENV;
					local function module(name, ...)
						local t = package.loaded[name] or _ENV[name] or { _NAME = name };
						package.loaded[name] = t;
						for i = 1, select("#", ...) do
							(select(i, ...))(t);
						end
						_ENV = t;
						_M = t;
						return t;
					end
				local verse = require "verse";

local xmlns_version = "jabber:iq:version";

local function set_version(self, version_info)
	self.name = version_info.name;
	self.version = version_info.version;
	self.platform = version_info.platform;
end

function verse.plugins.version(stream)
	stream.version = { set = set_version };
	stream:hook("iq/"..xmlns_version, function (stanza)
		if stanza.attr.type ~= "get" then return; end
		local reply = verse.reply(stanza)
			:tag("query", { xmlns = xmlns_version });
		if stream.version.name then
			reply:tag("name"):text(tostring(stream.version.name)):up();
		end
		if stream.version.version then
			reply:tag("version"):text(tostring(stream.version.version)):up()
		end
		if stream.version.platform then
			reply:tag("os"):text(stream.version.platform);
		end
		stream:send(reply);
		return true;
	end);

	function stream:query_version(target_jid, callback)
		callback = callback or function (version) return self:event("version/response", version); end
		self:send_iq(verse.iq({ type = "get", to = target_jid })
			:tag("query", { xmlns = xmlns_version }),
			function (reply)
				if reply.attr.type == "result" then
					local query = reply:get_child("query", xmlns_version);
					local name = query and query:get_child_text("name");
					local version = query and query:get_child_text("version");
					local os = query and query:get_child_text("os");
					callback({
						name = name;
						version = version;
						platform = os;
						});
				else
					local type, condition, text = reply:get_error();
					callback({
						error = true;
						condition = condition;
						text = text;
						type = type;
						});
				end
			end);
	end
	return true;
end
 end)
package.preload['verse.plugins.ping'] = (function (...)
					local _ENV = _ENV;
					local function module(name, ...)
						local t = package.loaded[name] or _ENV[name] or { _NAME = name };
						package.loaded[name] = t;
						for i = 1, select("#", ...) do
							(select(i, ...))(t);
						end
						_ENV = t;
						_M = t;
						return t;
					end
				local verse = require "verse";
local gettime = require"socket".gettime;

local xmlns_ping = "urn:xmpp:ping";

function verse.plugins.ping(stream)
	function stream:ping(jid, callback)
		local t = gettime();
		stream:send_iq(verse.iq{ to = jid, type = "get" }:tag("ping", { xmlns = xmlns_ping }),
			function (reply)
				if reply.attr.type == "error" then
					local type, condition, text = reply:get_error();
					if condition ~= "service-unavailable" and condition ~= "feature-not-implemented" then
						callback(nil, jid, { type = type, condition = condition, text = text });
						return;
					end
				end
				callback(gettime()-t, jid);
			end);
	end
	stream:hook("iq/"..xmlns_ping, function(stanza)
		return stream:send(verse.reply(stanza));
	end);
	return true;
end
 end)
package.preload['verse.plugins.uptime'] = (function (...)
					local _ENV = _ENV;
					local function module(name, ...)
						local t = package.loaded[name] or _ENV[name] or { _NAME = name };
						package.loaded[name] = t;
						for i = 1, select("#", ...) do
							(select(i, ...))(t);
						end
						_ENV = t;
						_M = t;
						return t;
					end
				local verse = require "verse";

local xmlns_last = "jabber:iq:last";

local function set_uptime(self, uptime_info)
	self.starttime = uptime_info.starttime;
end

function verse.plugins.uptime(stream)
	stream.uptime = { set = set_uptime };
	stream:hook("iq/"..xmlns_last, function (stanza)
		if stanza.attr.type ~= "get" then return; end
		local reply = verse.reply(stanza)
			:tag("query", { seconds = tostring(os.difftime(os.time(), stream.uptime.starttime)), xmlns = xmlns_last });
		stream:send(reply);
		return true;
	end);

	function stream:query_uptime(target_jid, callback)
		callback = callback or function (uptime) return stream:event("uptime/response", uptime); end
		stream:send_iq(verse.iq({ type = "get", to = target_jid })
			:tag("query", { xmlns = xmlns_last }),
			function (reply)
				local query = reply:get_child("query", xmlns_last);
				if reply.attr.type == "result" then
					local seconds = tonumber(query.attr.seconds);
					callback({
						seconds = seconds or nil;
						});
				else
					local type, condition, text = reply:get_error();
					callback({
						error = true;
						condition = condition;
						text = text;
						type = type;
						});
				end
			end);
	end
	return true;
end
 end)
package.preload['verse.plugins.blocking'] = (function (...)
					local _ENV = _ENV;
					local function module(name, ...)
						local t = package.loaded[name] or _ENV[name] or { _NAME = name };
						package.loaded[name] = t;
						for i = 1, select("#", ...) do
							(select(i, ...))(t);
						end
						_ENV = t;
						_M = t;
						return t;
					end
				local verse = require "verse";

local xmlns_blocking = "urn:xmpp:blocking";

function verse.plugins.blocking(stream)
	-- FIXME: Disco
	stream.blocking = {};
	function stream.blocking:block_jid(jid, callback)
		stream:send_iq(verse.iq{type="set"}
			:tag("block", { xmlns = xmlns_blocking })
				:tag("item", { jid = jid })
			, function () return callback and callback(true); end
			, function () return callback and callback(false); end
		);
	end
	function stream.blocking:unblock_jid(jid, callback)
		stream:send_iq(verse.iq{type="set"}
			:tag("unblock", { xmlns = xmlns_blocking })
				:tag("item", { jid = jid })
			, function () return callback and callback(true); end
			, function () return callback and callback(false); end
		);
	end
	function stream.blocking:unblock_all_jids(callback)
		stream:send_iq(verse.iq{type="set"}
			:tag("unblock", { xmlns = xmlns_blocking })
			, function () return callback and callback(true); end
			, function () return callback and callback(false); end
		);
	end
	function stream.blocking:get_blocked_jids(callback)
		stream:send_iq(verse.iq{type="get"}
			:tag("blocklist", { xmlns = xmlns_blocking })
			, function (result)
				local list = result:get_child("blocklist", xmlns_blocking);
				if not list then return callback and callback(false); end
				local jids = {};
				for item in list:childtags() do
					jids[#jids+1] = item.attr.jid;
				end
				return callback and callback(jids);
			  end
			, function (result) return callback and callback(false); end
		);
	end
end
 end)
package.preload['verse.plugins.jingle'] = (function (...)
					local _ENV = _ENV;
					local function module(name, ...)
						local t = package.loaded[name] or _ENV[name] or { _NAME = name };
						package.loaded[name] = t;
						for i = 1, select("#", ...) do
							(select(i, ...))(t);
						end
						_ENV = t;
						_M = t;
						return t;
					end
				local verse = require "verse";
local timer = require "util.timer";
local uuid_generate = require "util.uuid".generate;

local xmlns_jingle = "urn:xmpp:jingle:1";
local xmlns_jingle_errors = "urn:xmpp:jingle:errors:1";

local jingle_mt = {};
jingle_mt.__index = jingle_mt;

local registered_transports = {};
local registered_content_types = {};

function verse.plugins.jingle(stream)
	stream:hook("ready", function ()
		stream:add_disco_feature(xmlns_jingle);
	end, 10);

	function stream:jingle(to)
		return verse.eventable(setmetatable(base or {
			role = "initiator";
			peer = to;
			sid = uuid_generate();
			stream = stream;
		}, jingle_mt));
	end

	function stream:register_jingle_transport(transport)
		-- transport is a function that receives a
		-- <transport> element, and returns a connection
		-- We wait for 'connected' on that connection,
		-- and use :send() and 'incoming-raw'.
	end

	function stream:register_jingle_content_type(content)
		-- Call content() for every 'incoming-raw'?
		-- I think content() returns the object we return
		-- on jingle:accept()
	end

	local function handle_incoming_jingle(stanza)
		local jingle_tag = stanza:get_child("jingle", xmlns_jingle);
		local sid = jingle_tag.attr.sid;
		local action = jingle_tag.attr.action;
		local result = stream:event("jingle/"..sid, stanza);
		if result == true then
			-- Ack
			stream:send(verse.reply(stanza));
			return true;
		end
		-- No existing Jingle object handled this action, our turn...
		if action ~= "session-initiate" then
			-- Trying to send a command to a session we don't know
			local reply = verse.error_reply(stanza, "cancel", "item-not-found")
				:tag("unknown-session", { xmlns = xmlns_jingle_errors }):up();
			stream:send(reply);
			return;
		end

		-- Ok, session-initiate, new session

		-- Create new Jingle object
		local sid = jingle_tag.attr.sid;

		local jingle = verse.eventable{
			role = "receiver";
			peer = stanza.attr.from;
			sid = sid;
			stream = stream;
		};

		setmetatable(jingle, jingle_mt);

		local content_tag;
		local content, transport;
		for tag in jingle_tag:childtags() do
			if tag.name == "content" and tag.attr.xmlns == xmlns_jingle then
			 	local description_tag = tag:child_with_name("description");
			 	local description_xmlns = description_tag.attr.xmlns;
			 	if description_xmlns then
			 		local desc_handler = stream:event("jingle/content/"..description_xmlns, jingle, description_tag);
			 		if desc_handler then
			 			content = desc_handler;
			 		end
			 	end

				local transport_tag = tag:child_with_name("transport");
				local transport_xmlns = transport_tag.attr.xmlns;

				transport = stream:event("jingle/transport/"..transport_xmlns, jingle, transport_tag);
				if content and transport then
					content_tag = tag;
					break;
				end
			end
		end
		if not content then
			-- FIXME: Fail, no content
			stream:send(verse.error_reply(stanza, "cancel", "feature-not-implemented", "The specified content is not supported"));
			return true;
		end

		if not transport then
			-- FIXME: Refuse session, no transport
			stream:send(verse.error_reply(stanza, "cancel", "feature-not-implemented", "The specified transport is not supported"));
			return true;
		end

		stream:send(verse.reply(stanza));

		jingle.content_tag = content_tag;
		jingle.creator, jingle.name = content_tag.attr.creator, content_tag.attr.name;
		jingle.content, jingle.transport = content, transport;

		function jingle:decline()
			-- FIXME: Decline session
		end

		stream:hook("jingle/"..sid, function (stanza)
			if stanza.attr.from ~= jingle.peer then
				return false;
			end
			local jingle_tag = stanza:get_child("jingle", xmlns_jingle);
			return jingle:handle_command(jingle_tag);
		end);

		stream:event("jingle", jingle);
		return true;
	end

	function jingle_mt:handle_command(jingle_tag)
		local action = jingle_tag.attr.action;
		stream:debug("Handling Jingle command: %s", action);
		if action == "session-terminate" then
			self:destroy();
		elseif action == "session-accept" then
			-- Yay!
			self:handle_accepted(jingle_tag);
		elseif action == "transport-info" then
			stream:debug("Handling transport-info");
			self.transport:info_received(jingle_tag);
		elseif action == "transport-replace" then
			-- FIXME: Used for IBB fallback
			stream:error("Peer wanted to swap transport, not implemented");
		else
			-- FIXME: Reply unhandled command
			stream:warn("Unhandled Jingle command: %s", action);
			return nil;
		end
		return true;
	end

	function jingle_mt:send_command(command, element, callback)
		local stanza = verse.iq({ to = self.peer, type = "set" })
			:tag("jingle", {
				xmlns = xmlns_jingle,
				sid = self.sid,
				action = command,
				initiator = self.role == "initiator" and self.stream.jid or nil,
				responder = self.role == "responder" and self.jid or nil,
			}):add_child(element);
		if not callback then
			self.stream:send(stanza);
		else
			self.stream:send_iq(stanza, callback);
		end
	end

	function jingle_mt:accept(options)
		local accept_stanza = verse.iq({ to = self.peer, type = "set" })
			:tag("jingle", {
				xmlns = xmlns_jingle,
				sid = self.sid,
				action = "session-accept",
				responder = stream.jid,
			})
				:tag("content", { creator = self.creator, name = self.name });

		local content_accept_tag = self.content:generate_accept(self.content_tag:child_with_name("description"), options);
		accept_stanza:add_child(content_accept_tag);

		local transport_accept_tag = self.transport:generate_accept(self.content_tag:child_with_name("transport"), options);
		accept_stanza:add_child(transport_accept_tag);

		local jingle = self;
		stream:send_iq(accept_stanza, function (result)
			if result.attr.type == "error" then
				local type, condition, text = result:get_error();
				stream:error("session-accept rejected: %s", condition); -- FIXME: Notify
				return false;
			end
			jingle.transport:connect(function (conn)
				stream:warn("CONNECTED (receiver)!!!");
				jingle.state = "active";
				jingle:event("connected", conn);
			end);
		end);
	end


	stream:hook("iq/"..xmlns_jingle, handle_incoming_jingle);
	return true;
end

function jingle_mt:offer(name, content)
	local session_initiate = verse.iq({ to = self.peer, type = "set" })
		:tag("jingle", { xmlns = xmlns_jingle, action = "session-initiate",
			initiator = self.stream.jid, sid = self.sid });

	-- Content tag
	session_initiate:tag("content", { creator = self.role, name = name });

	-- Need description element from someone who can turn 'content' into XML
	local description = self.stream:event("jingle/describe/"..name, content);

	if not description then
		return false, "Unknown content type";
	end

	session_initiate:add_child(description);

	-- FIXME: Sort transports by 1) recipient caps 2) priority (SOCKS vs IBB, etc.)
	-- Fixed to s5b in the meantime
	local transport = self.stream:event("jingle/transport/".."urn:xmpp:jingle:transports:s5b:1", self);
	self.transport = transport;

	session_initiate:add_child(transport:generate_initiate());

	self.stream:debug("Hooking %s", "jingle/"..self.sid);
	self.stream:hook("jingle/"..self.sid, function (stanza)
		if stanza.attr.from ~= self.peer then
			return false;
		end
		local jingle_tag = stanza:get_child("jingle", xmlns_jingle);
		return self:handle_command(jingle_tag)
	end);

	self.stream:send_iq(session_initiate, function (result)
		if result.attr.type == "error" then
			self.state = "terminated";
			local type, condition, text = result:get_error();
			return self:event("error", { type = type, condition = condition, text = text });
		end
	end);
	self.state = "pending";
end

function jingle_mt:terminate(reason)
	local reason_tag = verse.stanza("reason"):tag(reason or "success");
	self:send_command("session-terminate", reason_tag, function (result)
		self.state = "terminated";
		self.transport:disconnect();
		self:destroy();
	end);
end

function jingle_mt:destroy()
	self:event("terminated");
	self.stream:unhook("jingle/"..self.sid, self.handle_command);
end

function jingle_mt:handle_accepted(jingle_tag)
	local transport_tag = jingle_tag:child_with_name("transport");
	self.transport:handle_accepted(transport_tag);
	self.transport:connect(function (conn)
		self.stream:debug("CONNECTED (initiator)!")
		-- Connected, send file
		self.state = "active";
		self:event("connected", conn);
	end);
end

function jingle_mt:set_source(source, auto_close)
	local function pump()
		local chunk, err = source();
		if chunk and chunk ~= "" then
			self.transport.conn:send(chunk);
		elseif chunk == "" then
			return pump(); -- We need some data!
		elseif chunk == nil then
			if auto_close then
				self:terminate();
			end
			self.transport.conn:unhook("drained", pump);
			source = nil;
		end
	end
	self.transport.conn:hook("drained", pump);
	pump();
end

function jingle_mt:set_sink(sink)
	self.transport.conn:hook("incoming-raw", sink);
	self.transport.conn:hook("disconnected", function (event)
		self.stream:debug("Closing sink...");
		local reason = event.reason;
		if reason == "closed" then reason = nil; end
		sink(nil, reason);
	end);
end
 end)
package.preload['verse.plugins.jingle_ft'] = (function (...)
					local _ENV = _ENV;
					local function module(name, ...)
						local t = package.loaded[name] or _ENV[name] or { _NAME = name };
						package.loaded[name] = t;
						for i = 1, select("#", ...) do
							(select(i, ...))(t);
						end
						_ENV = t;
						_M = t;
						return t;
					end
				local verse = require "verse";
local ltn12 = require "ltn12";

local dirsep = package.config:sub(1,1);

local xmlns_jingle_ft = "urn:xmpp:jingle:apps:file-transfer:4";

function verse.plugins.jingle_ft(stream)
	stream:hook("ready", function ()
		stream:add_disco_feature(xmlns_jingle_ft);
	end, 10);

	local ft_content = { type = "file" };

	function ft_content:generate_accept(description, options)
		if options and options.save_file then
			self.jingle:hook("connected", function ()
				local sink = ltn12.sink.file(io.open(options.save_file, "w+"));
				self.jingle:set_sink(sink);
			end);
		end

		return description;
	end

	local ft_mt = { __index = ft_content };
	stream:hook("jingle/content/"..xmlns_jingle_ft, function (jingle, description_tag)
		local file_tag = description_tag:get_child("file");
		local file = {
			name = file_tag:get_child_text("name");
			size = tonumber(file_tag:get_child_text("size"));
			desc = file_tag:get_child_text("desc");
			date = file_tag:get_child_text("date");
		};

		return setmetatable({ jingle = jingle, file = file }, ft_mt);
	end);

	stream:hook("jingle/describe/file", function (file_info)
		-- Return <description/>
		local date;
		if file_info.timestamp then
			date = os.date("!%Y-%m-%dT%H:%M:%SZ", file_info.timestamp);
		end
		return verse.stanza("description", { xmlns = xmlns_jingle_ft })
			:tag("file")
				:tag("name"):text(file_info.filename):up()
				:tag("size"):text(tostring(file_info.size)):up()
				:tag("date"):text(date):up()
				:tag("desc"):text(file_info.description):up()
			:up();
	end);

	function stream:send_file(to, filename)
		local file, err = io.open(filename);
		if not file then return file, err; end

		local file_size = file:seek("end", 0);
		file:seek("set", 0);

		local source = ltn12.source.file(file);

		local jingle = self:jingle(to);
		jingle:offer("file", {
			filename = filename:match("[^"..dirsep.."]+$");
			size = file_size;
		});
		jingle:hook("connected", function ()
			jingle:set_source(source, true);
		end);
		return jingle;
	end
end
 end)
package.preload['verse.plugins.jingle_s5b'] = (function (...)
					local _ENV = _ENV;
					local function module(name, ...)
						local t = package.loaded[name] or _ENV[name] or { _NAME = name };
						package.loaded[name] = t;
						for i = 1, select("#", ...) do
							(select(i, ...))(t);
						end
						_ENV = t;
						_M = t;
						return t;
					end
				local verse = require "verse";

local xmlns_s5b = "urn:xmpp:jingle:transports:s5b:1";
local xmlns_bytestreams = "http://jabber.org/protocol/bytestreams";
local sha1 = require "util.hashes".sha1;
local uuid_generate = require "util.uuid".generate;

local function negotiate_socks5(conn, hash)
	local function suppress_connected()
		conn:unhook("connected", suppress_connected);
		return true;
	end
	local function receive_connection_response(data)
		conn:unhook("incoming-raw", receive_connection_response);

		if data:sub(1, 2) ~= "\005\000" then
			return conn:event("error", "connection-failure");
		end
		conn:event("connected");
		return true;
	end
	local function receive_auth_response(data)
		conn:unhook("incoming-raw", receive_auth_response);
		if data ~= "\005\000" then -- SOCKSv5; "NO AUTHENTICATION"
			-- Server is not SOCKSv5, or does not allow no auth
			local err = "version-mismatch";
			if data:sub(1,1) == "\005" then
				err = "authentication-failure";
			end
			return conn:event("error", err);
		end
		-- Request SOCKS5 connection
		conn:send(string.char(0x05, 0x01, 0x00, 0x03, #hash)..hash.."\0\0"); --FIXME: Move to "connected"?
		conn:hook("incoming-raw", receive_connection_response, 100);
		return true;
	end
	conn:hook("connected", suppress_connected, 200);
	conn:hook("incoming-raw", receive_auth_response, 100);
	conn:send("\005\001\000"); -- SOCKSv5; 1 mechanism; "NO AUTHENTICATION"
end

local function connect_to_usable_streamhost(callback, streamhosts, auth_token)
	local conn = verse.new(nil, {
		streamhosts = streamhosts,
		current_host = 0;
	});
	--Attempt to connect to the next host
	local function attempt_next_streamhost(event)
		if event then
			return callback(nil, event.reason);
		end
		-- First connect, or the last connect failed
		if conn.current_host < #conn.streamhosts then
			conn.current_host = conn.current_host + 1;
			conn:debug("Attempting to connect to "..conn.streamhosts[conn.current_host].host..":"..conn.streamhosts[conn.current_host].port.."...");
			local ok, err = conn:connect(
				conn.streamhosts[conn.current_host].host,
				conn.streamhosts[conn.current_host].port
			);
			if not ok then
				conn:debug("Error connecting to proxy (%s:%s): %s",
					conn.streamhosts[conn.current_host].host,
					conn.streamhosts[conn.current_host].port,
					err
				);
			else
				conn:debug("Connecting...");
			end
			negotiate_socks5(conn, auth_token);
			return true; -- Halt processing of disconnected event
		end
		-- All streamhosts tried, none successful
		conn:unhook("disconnected", attempt_next_streamhost);
		return callback(nil);
		-- Let disconnected event fall through to user handlers...
	end
	conn:hook("disconnected", attempt_next_streamhost, 100);
	-- When this event fires, we're connected to a streamhost
	conn:hook("connected", function ()
		conn:unhook("disconnected", attempt_next_streamhost);
		callback(conn.streamhosts[conn.current_host], conn);
	end, 100);
	attempt_next_streamhost(); -- Set it in motion
	return conn;
end

function verse.plugins.jingle_s5b(stream)
	stream:hook("ready", function ()
		stream:add_disco_feature(xmlns_s5b);
	end, 10);

	local s5b = {};

	function s5b:generate_initiate()
		self.s5b_sid = uuid_generate();
		local transport = verse.stanza("transport", { xmlns = xmlns_s5b,
			mode = "tcp", sid = self.s5b_sid });
		local p = 0;
		for jid, streamhost in pairs(stream.proxy65.available_streamhosts) do
			p = p + 1;
			transport:tag("candidate", { jid = jid, host = streamhost.host,
				port = streamhost.port, cid=jid, priority = p, type = "proxy" }):up();
		end
		stream:debug("Have %d proxies", p)
		return transport;
	end

	function s5b:generate_accept(initiate_transport)
		local candidates = {};
		self.s5b_peer_candidates = candidates;
		self.s5b_mode = initiate_transport.attr.mode or "tcp";
		self.s5b_sid = initiate_transport.attr.sid or self.jingle.sid;

		-- Import the list of candidates the initiator offered us
		for candidate in initiate_transport:childtags() do
			--if candidate.attr.jid == "asterix4@jabber.lagaule.org/Gajim"
			--and candidate.attr.host == "82.246.25.239" then
				candidates[candidate.attr.cid] = {
					type = candidate.attr.type;
					jid = candidate.attr.jid;
					host = candidate.attr.host;
					port = tonumber(candidate.attr.port) or 0;
					priority = tonumber(candidate.attr.priority) or 0;
					cid = candidate.attr.cid;
				};
			--end
		end

		-- Import our own candidates
		-- TODO ^
		local transport = verse.stanza("transport", { xmlns = xmlns_s5b });
		return transport;
	end

	function s5b:connect(callback)
		stream:warn("Connecting!");

		local streamhost_array = {};
		for cid, streamhost in pairs(self.s5b_peer_candidates or {}) do
			streamhost_array[#streamhost_array+1] = streamhost;
		end

		if #streamhost_array > 0 then
			self.connecting_peer_candidates = true;
			local function onconnect(streamhost, conn)
				self.jingle:send_command("transport-info", verse.stanza("content", { creator = self.creator, name = self.name })
					:tag("transport", { xmlns = xmlns_s5b, sid = self.s5b_sid })
						:tag("candidate-used", { cid = streamhost.cid }));
				self.onconnect_callback = callback;
				self.conn = conn;
			end
			local auth_token = sha1(self.s5b_sid..self.peer..stream.jid, true);
			connect_to_usable_streamhost(onconnect, streamhost_array, auth_token);
		else
			stream:warn("Actually, I'm going to wait for my peer to tell me its streamhost...");
			self.onconnect_callback = callback;
		end
	end

	function s5b:info_received(jingle_tag)
		stream:warn("Info received");
		local content_tag = jingle_tag:child_with_name("content");
		local transport_tag = content_tag:child_with_name("transport");
		if transport_tag:get_child("candidate-used") and not self.connecting_peer_candidates then
			local candidate_used = transport_tag:child_with_name("candidate-used");
			if candidate_used then
				-- Connect straight away to candidate used, we weren't trying any anyway
				local function onconnect(streamhost, conn)
					if self.jingle.role == "initiator" then -- More correct would be - "is this a candidate we offered?"
						-- Activate the stream
						self.jingle.stream:send_iq(verse.iq({ to = streamhost.jid, type = "set" })
							:tag("query", { xmlns = xmlns_bytestreams, sid = self.s5b_sid })
								:tag("activate"):text(self.jingle.peer), function (result)

							if result.attr.type == "result" then
								self.jingle:send_command("transport-info", verse.stanza("content", content_tag.attr)
									:tag("transport", { xmlns = xmlns_s5b, sid = self.s5b_sid })
										:tag("activated", { cid = candidate_used.attr.cid }));
								self.conn = conn;
								self.onconnect_callback(conn);
							else
								self.jingle.stream:error("Failed to activate bytestream");
							end
						end);
					end
				end

				-- FIXME: Another assumption that cid==jid, and that it was our candidate
				self.jingle.stream:debug("CID: %s", self.jingle.stream.proxy65.available_streamhosts[candidate_used.attr.cid]);
				local streamhost_array = {
					self.jingle.stream.proxy65.available_streamhosts[candidate_used.attr.cid];
				};

				local auth_token = sha1(self.s5b_sid..stream.jid..self.peer, true);
				connect_to_usable_streamhost(onconnect, streamhost_array, auth_token);
			end
		elseif transport_tag:get_child("activated") then
			self.onconnect_callback(self.conn);
		end
	end

	function s5b:disconnect()
		if self.conn then
			self.conn:close();
		end
	end

	function s5b:handle_accepted(jingle_tag)
	end

	local s5b_mt = { __index = s5b };
	stream:hook("jingle/transport/"..xmlns_s5b, function (jingle)
		return setmetatable({
			role = jingle.role,
			peer = jingle.peer,
			stream = jingle.stream,
			jingle = jingle,
		}, s5b_mt);
	end);
end
 end)
package.preload['verse.plugins.proxy65'] = (function (...)
					local _ENV = _ENV;
					local function module(name, ...)
						local t = package.loaded[name] or _ENV[name] or { _NAME = name };
						package.loaded[name] = t;
						for i = 1, select("#", ...) do
							(select(i, ...))(t);
						end
						_ENV = t;
						_M = t;
						return t;
					end
				local verse =	require "verse";
local uuid = require "util.uuid";
local sha1 = require "util.hashes".sha1;

local proxy65_mt = {};
proxy65_mt.__index = proxy65_mt;

local xmlns_bytestreams = "http://jabber.org/protocol/bytestreams";

local negotiate_socks5;

function verse.plugins.proxy65(stream)
	stream.proxy65 = setmetatable({ stream = stream }, proxy65_mt);
	stream.proxy65.available_streamhosts = {};
	local outstanding_proxies = 0;
	stream:hook("disco/service-discovered/proxy", function (service)
		-- Fill list with available proxies
		if service.type == "bytestreams" then
			outstanding_proxies = outstanding_proxies + 1;
			stream:send_iq(verse.iq({ to = service.jid, type = "get" })
				:tag("query", { xmlns = xmlns_bytestreams }), function (result)

				outstanding_proxies = outstanding_proxies - 1;
				if result.attr.type == "result" then
					local streamhost = result:get_child("query", xmlns_bytestreams)
						:get_child("streamhost").attr;

					stream.proxy65.available_streamhosts[streamhost.jid] = {
						jid = streamhost.jid;
						host = streamhost.host;
						port = tonumber(streamhost.port);
					};
				end
				if outstanding_proxies == 0 then
					stream:event("proxy65/discovered-proxies", stream.proxy65.available_streamhosts);
				end
			end);
		end
	end);
	stream:hook("iq/"..xmlns_bytestreams, function (request)
		local conn = verse.new(nil, {
			initiator_jid = request.attr.from,
			streamhosts = {},
			current_host = 0;
		});

		-- Parse hosts from request
		for tag in request.tags[1]:childtags() do
			if tag.name == "streamhost" then
				table.insert(conn.streamhosts, tag.attr);
			end
		end

		--Attempt to connect to the next host
		local function attempt_next_streamhost()
			-- First connect, or the last connect failed
			if conn.current_host < #conn.streamhosts then
				conn.current_host = conn.current_host + 1;
				conn:connect(
					conn.streamhosts[conn.current_host].host,
					conn.streamhosts[conn.current_host].port
				);
				negotiate_socks5(stream, conn, request.tags[1].attr.sid, request.attr.from, stream.jid);
				return true; -- Halt processing of disconnected event
			end
			-- All streamhosts tried, none successful
			conn:unhook("disconnected", attempt_next_streamhost);
			stream:send(verse.error_reply(request, "cancel", "item-not-found"));
			-- Let disconnected event fall through to user handlers...
		end

		function conn:accept()
			conn:hook("disconnected", attempt_next_streamhost, 100);
			-- When this event fires, we're connected to a streamhost
			conn:hook("connected", function ()
				conn:unhook("disconnected", attempt_next_streamhost);
				-- Send XMPP success notification
				local reply = verse.reply(request)
					:tag("query", request.tags[1].attr)
					:tag("streamhost-used", { jid = conn.streamhosts[conn.current_host].jid });
				stream:send(reply);
			end, 100);
			attempt_next_streamhost();
		end
		function conn:refuse()
			-- FIXME: XMPP refused reply
		end
		stream:event("proxy65/request", conn);
	end);
end

function proxy65_mt:new(target_jid, proxies)
	local conn = verse.new(nil, {
		target_jid = target_jid;
		bytestream_sid = uuid.generate();
	});

	local request = verse.iq{type="set", to = target_jid}
		:tag("query", { xmlns = xmlns_bytestreams, mode = "tcp", sid = conn.bytestream_sid });
	for _, proxy in ipairs(proxies or self.proxies) do
		request:tag("streamhost", proxy):up();
	end


	self.stream:send_iq(request, function (reply)
		if reply.attr.type == "error" then
			local type, condition, text = reply:get_error();
			conn:event("connection-failed", { conn = conn, type = type, condition = condition, text = text });
		else
			-- Target connected to streamhost, connect ourselves
			local streamhost_used = reply.tags[1]:get_child("streamhost-used");
			-- if not streamhost_used then
				--FIXME: Emit error
			-- end
			conn.streamhost_jid = streamhost_used.attr.jid;
			local host, port;
			for _, proxy in ipairs(proxies or self.proxies) do
				if proxy.jid == conn.streamhost_jid then
					host, port = proxy.host, proxy.port;
					break;
				end
			end
			-- if not (host and port) then
				--FIXME: Emit error
			-- end

			conn:connect(host, port);

			local function handle_proxy_connected()
				conn:unhook("connected", handle_proxy_connected);
				-- Both of us connected, tell proxy to activate connection
				local activate_request = verse.iq{to = conn.streamhost_jid, type="set"}
					:tag("query", { xmlns = xmlns_bytestreams, sid = conn.bytestream_sid })
						:tag("activate"):text(target_jid);
				self.stream:send_iq(activate_request, function (activated)
					if activated.attr.type == "result" then
						-- Connection activated, ready to use
						conn:event("connected", conn);
					-- else --FIXME: Emit error
					end
				end);
				return true;
			end
			conn:hook("connected", handle_proxy_connected, 100);

			negotiate_socks5(self.stream, conn, conn.bytestream_sid, self.stream.jid, target_jid);
		end
	end);
	return conn;
end

function negotiate_socks5(stream, conn, sid, requester_jid, target_jid)
	local hash = sha1(sid..requester_jid..target_jid);
	local function suppress_connected()
		conn:unhook("connected", suppress_connected);
		return true;
	end
	local function receive_connection_response(data)
		conn:unhook("incoming-raw", receive_connection_response);

		if data:sub(1, 2) ~= "\005\000" then
			return conn:event("error", "connection-failure");
		end
		conn:event("connected");
		return true;
	end
	local function receive_auth_response(data)
		conn:unhook("incoming-raw", receive_auth_response);
		if data ~= "\005\000" then -- SOCKSv5; "NO AUTHENTICATION"
			-- Server is not SOCKSv5, or does not allow no auth
			local err = "version-mismatch";
			if data:sub(1,1) == "\005" then
				err = "authentication-failure";
			end
			return conn:event("error", err);
		end
		-- Request SOCKS5 connection
		conn:send(string.char(0x05, 0x01, 0x00, 0x03, #hash)..hash.."\0\0"); --FIXME: Move to "connected"?
		conn:hook("incoming-raw", receive_connection_response, 100);
		return true;
	end
	conn:hook("connected", suppress_connected, 200);
	conn:hook("incoming-raw", receive_auth_response, 100);
	conn:send("\005\001\000"); -- SOCKSv5; 1 mechanism; "NO AUTHENTICATION"
end
 end)
package.preload['verse.plugins.jingle_ibb'] = (function (...)
					local _ENV = _ENV;
					local function module(name, ...)
						local t = package.loaded[name] or _ENV[name] or { _NAME = name };
						package.loaded[name] = t;
						for i = 1, select("#", ...) do
							(select(i, ...))(t);
						end
						_ENV = t;
						_M = t;
						return t;
					end
				local verse = require "verse";
local base64 = require "util.encodings".base64;
local uuid_generate = require "util.uuid".generate;

local xmlns_jingle_ibb = "urn:xmpp:jingle:transports:ibb:1";
local xmlns_ibb = "http://jabber.org/protocol/ibb";
assert(base64.encode("This is a test.") == "VGhpcyBpcyBhIHRlc3Qu", "Base64 encoding failed");
assert(base64.decode("VGhpcyBpcyBhIHRlc3Qu") == "This is a test.", "Base64 decoding failed");
local t_concat = table.concat

local ibb_conn = {};
local ibb_conn_mt = { __index = ibb_conn };

local function new_ibb(stream)
	local conn = setmetatable({ stream = stream }, ibb_conn_mt)
	conn = verse.eventable(conn);
	return conn;
end

function ibb_conn:initiate(peer, sid, stanza)
	self.block = 2048; -- ignored for now
	self.stanza = stanza or 'iq';
	self.peer = peer;
	self.sid = sid or tostring(self):match("%x+$");
	self.iseq = 0;
	self.oseq = 0;
	local feeder = function(stanza)
		return self:feed(stanza)
	end
	self.feeder = feeder;
	print("Hooking incoming IQs");
	local stream = self.stream;
		stream:hook("iq/".. xmlns_ibb, feeder)
	if stanza == "message" then
		stream:hook("message", feeder)
	end
end

function ibb_conn:open(callback)
	self.stream:send_iq(verse.iq{ to = self.peer, type = "set" }
		:tag("open", {
			xmlns = xmlns_ibb,
			["block-size"] = self.block,
			sid = self.sid,
			stanza = self.stanza
		})
	, function(reply)
		if callback then
			if reply.attr.type ~= "error" then
				callback(true)
			else
				callback(false, reply:get_error())
			end
		end
	end);
end

function ibb_conn:send(data)
	local stanza = self.stanza;
	local st;
	if stanza == "iq" then
		st = verse.iq{ type = "set", to = self.peer }
	elseif stanza == "message" then
		st = verse.message{ to = self.peer }
	end

	local seq = self.oseq;
	self.oseq = seq + 1;

	st:tag("data", { xmlns = xmlns_ibb, sid = self.sid, seq = seq })
		:text(base64.encode(data));

	if stanza == "iq" then
		self.stream:send_iq(st, function(reply)
			self:event(reply.attr.type == "result" and "drained" or "error");
		end)
	else
		stream:send(st)
		self:event("drained");
	end
end

function ibb_conn:feed(stanza)
	if stanza.attr.from ~= self.peer then return end
	local child = stanza[1];
	if child.attr.sid ~= self.sid then return end
	local ok;
	if child.name == "open" then
		self:event("connected");
		self.stream:send(verse.reply(stanza))
		return true
	elseif child.name == "data" then
		local bdata = stanza:get_child_text("data", xmlns_ibb);
		local seq = tonumber(child.attr.seq);
		local expected_seq = self.iseq;
		if bdata and seq then
			if seq ~= expected_seq then
				self.stream:send(verse.error_reply(stanza, "cancel", "not-acceptable", "Wrong sequence. Packet lost?"))
				self:close();
				self:event("error");
				return true;
			end
			self.iseq = seq + 1;
			local data = base64.decode(bdata);
			if self.stanza == "iq" then
				self.stream:send(verse.reply(stanza))
			end
			self:event("incoming-raw", data);
			return true;
		end
	elseif child.name == "close" then
		self.stream:send(verse.reply(stanza))
		self:close();
		return true
	end
end

--[[ FIXME some day
function ibb_conn:receive(patt)
	-- is this even used?
	print("ibb_conn:receive("..tostring(patt)..")");
	assert(patt == "*a" or tonumber(patt));
	local data = t_concat(self.ibuffer):sub(self.pos, tonumber(patt) or nil);
	self.pos = self.pos + #data;
	return data
end

function ibb_conn:dirty()
	print("ibb_conn:dirty()");
	return false -- ????
end
function ibb_conn:getfd()
	return 0
end
function ibb_conn:settimeout(n)
	-- ignore?
end
-]]

function ibb_conn:close()
	self.stream:unhook("iq/".. xmlns_ibb, self.feeder)
	self:event("disconnected");
end

function verse.plugins.jingle_ibb(stream)
	stream:hook("ready", function ()
		stream:add_disco_feature(xmlns_jingle_ibb);
	end, 10);

	local ibb = {};

	function ibb:_setup()
		local conn = new_ibb(self.stream);
		conn.sid    = self.sid    or conn.sid;
		conn.stanza = self.stanza or conn.stanza;
		conn.block  = self.block  or conn.block;
		conn:initiate(self.peer, self.sid, self.stanza);
		self.conn = conn;
	end
	function ibb:generate_initiate()
		print("ibb:generate_initiate() as ".. self.role);
		local sid = uuid_generate();
		self.sid = sid;
		self.stanza = 'iq';
		self.block = 2048;
		local transport = verse.stanza("transport", { xmlns = xmlns_jingle_ibb,
			sid = self.sid, stanza = self.stanza, ["block-size"] = self.block });
		return transport;
	end
	function ibb:generate_accept(initiate_transport)
		print("ibb:generate_accept() as ".. self.role);
		local attr = initiate_transport.attr;
		self.sid    = attr.sid    or self.sid;
		self.stanza = attr.stanza or self.stanza;
		self.block  = attr["block-size"] or self.block;
		self:_setup();
		return initiate_transport;
	end
	function ibb:connect(callback)
		if not self.conn then
			self:_setup();
		end
		local conn = self.conn;
		print("ibb:connect() as ".. self.role);
		if self.role == "initiator" then
			conn:open(function(ok, ...)
				assert(ok, table.concat({...}, ", "));
				callback(conn);
			end);
		else
			callback(conn);
		end
	end
	function ibb:info_received(jingle_tag)
		print("ibb:info_received()");
		-- TODO, what exactly?
	end
	function ibb:disconnect()
		if self.conn then
			self.conn:close()
		end
	end
	function ibb:handle_accepted(jingle_tag) end

	local ibb_mt = { __index = ibb };
	stream:hook("jingle/transport/"..xmlns_jingle_ibb, function (jingle)
		return setmetatable({
			role = jingle.role,
			peer = jingle.peer,
			stream = jingle.stream,
			jingle = jingle,
		}, ibb_mt);
	end);
end
 end)
package.preload['verse.plugins.pubsub'] = (function (...)
					local _ENV = _ENV;
					local function module(name, ...)
						local t = package.loaded[name] or _ENV[name] or { _NAME = name };
						package.loaded[name] = t;
						for i = 1, select("#", ...) do
							(select(i, ...))(t);
						end
						_ENV = t;
						_M = t;
						return t;
					end
				local verse = require "verse";

local t_insert = table.insert;

local xmlns_pubsub = "http://jabber.org/protocol/pubsub";
local xmlns_pubsub_owner = "http://jabber.org/protocol/pubsub#owner";
local xmlns_pubsub_event = "http://jabber.org/protocol/pubsub#event";
-- local xmlns_pubsub_errors = "http://jabber.org/protocol/pubsub#errors";

local pubsub = {};
local pubsub_mt = { __index = pubsub };

function verse.plugins.pubsub(stream)
	stream.pubsub = setmetatable({ stream = stream }, pubsub_mt);
	stream:hook("message", function (message)
		local m_from = message.attr.from;
		for pubsub_event in message:childtags("event", xmlns_pubsub_event) do
			local items = pubsub_event:get_child("items");
			if items then
				local node = items.attr.node;
				for item in items:childtags("item") do
					stream:event("pubsub/event", {
						from = m_from;
						node = node;
						item = item;
					});
				end
			end
		end
	end);
	return true;
end

-- COMPAT
function pubsub:create(server, node, callback)
	return self:service(server):node(node):create(nil, callback);
end

function pubsub:subscribe(server, node, jid, callback)
	return self:service(server):node(node):subscribe(jid, nil, callback);
end

function pubsub:publish(server, node, id, item, callback)
	return self:service(server):node(node):publish(id, nil, item, callback);
end

--------------------------------------------------------------------------
---------------------New and improved PubSub interface--------------------
--------------------------------------------------------------------------

local pubsub_service = {};
local pubsub_service_mt = { __index = pubsub_service };

-- TODO should the property be named 'jid' instead?
function pubsub:service(service)
	return setmetatable({ stream = self.stream, service = service }, pubsub_service_mt)
end

-- Helper function for iq+pubsub tags

local function pubsub_iq(iq_type, to, ns, op, node, jid, item_id, op_attr_extra)
	local st = verse.iq{ type = iq_type or "get", to = to }
		:tag("pubsub", { xmlns = ns or xmlns_pubsub }) -- ns would be ..#owner
			local op_attr = { node = node, jid = jid };
			if op_attr_extra then
				for k, v in pairs(op_attr_extra) do
					op_attr[k] = v;
				end
			end
			if op then st:tag(op, op_attr); end
			if item_id then
				st:tag("item", { id = item_id ~= true and item_id or nil });
			end
	return st;
end

-- http://xmpp.org/extensions/xep-0060.html#entity-subscriptions
function pubsub_service:subscriptions(callback)
	self.stream:send_iq(pubsub_iq(nil, self.service, nil, "subscriptions")
	, callback and function (result)
		if result.attr.type == "result" then
			local ps = result:get_child("pubsub", xmlns_pubsub);
			local subs = ps and ps:get_child("subscriptions");
			local nodes = {};
			if subs then
				for sub in subs:childtags("subscription") do
					local node = self:node(sub.attr.node)
					node.subscription = sub;
					node.subscribed_jid = sub.attr.jid;
					t_insert(nodes, node);
					-- FIXME Good enough?
					-- Or how about:
					-- nodes[node] = sub;
				end
			end
			callback(nodes);
		else
			callback(false, result:get_error());
		end
	end or nil);
end

-- http://xmpp.org/extensions/xep-0060.html#entity-affiliations
function pubsub_service:affiliations(callback)
	self.stream:send_iq(pubsub_iq(nil, self.service, nil, "affiliations")
	, callback and function (result)
		if result.attr.type == "result" then
			local ps = result:get_child("pubsub", xmlns_pubsub);
			local affils = ps and ps:get_child("affiliations") or {};
			local nodes = {};
			if affils then
				for affil in affils:childtags("affiliation") do
					local node = self:node(affil.attr.node)
					node.affiliation = affil;
					t_insert(nodes, node);
					-- nodes[node] = affil;
				end
			end
			callback(nodes);
		else
			callback(false, result:get_error());
		end
	end or nil);
end

function pubsub_service:nodes(callback)
	self.stream:disco_items(self.service, nil, function(items, ...)
		if items then
			for i=1,#items do
				items[i] = self:node(items[i].node);
			end
		end
		callback(items, ...)
	end);
end

local pubsub_node = {};
local pubsub_node_mt = { __index = pubsub_node };

function pubsub_service:node(node)
	return setmetatable({ stream = self.stream, service = self.service, node = node }, pubsub_node_mt)
end

function pubsub_mt:__call(service, node)
	local s = self:service(service);
	return node and s:node(node) or s;
end

function pubsub_node:hook(callback, prio)
	self._hooks = self._hooks or setmetatable({}, { __mode = 'kv' });
	local function hook(event)
		-- FIXME service == nil would mean anyone,
		-- publishing would be go to your bare jid.
		-- So if you're only interestied in your own
		-- events, hook your own bare jid.
		if (not event.service or event.from == self.service) and event.node == self.node then
			return callback(event)
		end
	end
	self._hooks[callback] = hook;
	self.stream:hook("pubsub/event", hook, prio);
	return hook;
end

function pubsub_node:unhook(callback)
	if callback then
		local hook = self._hooks[callback];
		self.stream:unhook("pubsub/event", hook);
	elseif self._hooks then
		for hook in pairs(self._hooks) do
			self.stream:unhook("pubsub/event", hook);
		end
	end
end

function pubsub_node:create(config, callback)
	if config ~= nil then
		error("Not implemented yet.");
	else
		self.stream:send_iq(pubsub_iq("set", self.service, nil, "create", self.node), callback);
	end
end

-- <configure/> and <default/> rolled into one
function pubsub_node:configure(config, callback)
	if config ~= nil then
		error("Not implemented yet.");
		--[[
		if config == true then
			self.stream:send_iq(pubsub_iq("get", self.service, nil, "configure", self.node)
			, function(reply)
				local form = reply:get_child("pubsub"):get_child("configure"):get_cild("x");
				local config = callback(require"util.dataforms".something(form))
				self.stream:send_iq(pubsub_iq("set", config, ...))
			end);
		end
		--]]
		-- fetch form and pass it to the callback
		-- which would process it and pass it back
		-- and then we submit it
		-- elseif type(config) == "table" then
		-- it's a form or stanza that we submit
		-- end
		-- this would be done for everything that needs a config
	end
	self.stream:send_iq(pubsub_iq("set", self.service, nil, config == nil and "default" or "configure", self.node), callback);
end

function pubsub_node:publish(id, options, node, callback)
	if options ~= nil then
		error("Node configuration is not implemented yet.");
	end
	self.stream:send_iq(pubsub_iq("set", self.service, nil, "publish", self.node, nil, id or true)
	:add_child(node)
	, callback);
end

function pubsub_node:subscribe(jid, options, callback)
	jid = jid or self.stream.jid;
	if options ~= nil then
		error("Subscription configuration is not implemented yet.");
	end
	self.stream:send_iq(pubsub_iq("set", self.service, nil, "subscribe", self.node, jid)
	, callback);
end

function pubsub_node:subscription(callback)
	error("Not implemented yet.");
end

function pubsub_node:affiliation(callback)
	error("Not implemented yet.");
end

function pubsub_node:unsubscribe(jid, callback)
	jid = jid or self.subscribed_jid or self.stream.jid;
	self.stream:send_iq(pubsub_iq("set", self.service, nil, "unsubscribe", self.node, jid)
	, callback);
end

function pubsub_node:configure_subscription(options, callback)
	error("Not implemented yet.");
end

function pubsub_node:items(full, callback)
	if full then
		self.stream:send_iq(pubsub_iq("get", self.service, nil, "items", self.node)
		, callback);
	else
		self.stream:disco_items(self.service, self.node, callback);
	end
end

function pubsub_node:item(id, callback)
	self.stream:send_iq(pubsub_iq("get", self.service, nil, "items", self.node, nil, id)
	, callback);
end

function pubsub_node:retract(id, notify, callback)
	if type(notify) == "function" then -- COMPAT w/ older versions before 'notify' was added
		notify, callback = false, notify;
	end
	self.stream:send_iq(
		pubsub_iq(
			"set",
			self.service,
			nil,
			"retract",
			self.node,
			nil,
			id,
			{ notify = notify and "1" or nil }
		),
		callback
	);
end

function pubsub_node:purge(notify, callback)
	self.stream:send_iq(
		pubsub_iq(
			"set",
			self.service,
			xmlns_pubsub_owner,
			"purge",
			self.node,
			nil,
			nil,
			{ notify = notify and "1" or nil }
		),
		callback
	);
end

function pubsub_node:delete(redirect_uri, callback)
	assert(not redirect_uri, "Not implemented yet.");
	self.stream:send_iq(pubsub_iq("set", self.service, xmlns_pubsub_owner, "delete", self.node)
	, callback);
end
 end)
package.preload['verse.plugins.pep'] = (function (...)
					local _ENV = _ENV;
					local function module(name, ...)
						local t = package.loaded[name] or _ENV[name] or { _NAME = name };
						package.loaded[name] = t;
						for i = 1, select("#", ...) do
							(select(i, ...))(t);
						end
						_ENV = t;
						_M = t;
						return t;
					end
				local verse = require "verse";

local xmlns_pubsub = "http://jabber.org/protocol/pubsub";
local xmlns_pubsub_event = xmlns_pubsub.."#event";

function verse.plugins.pep(stream)
	stream:add_plugin("disco");
	stream:add_plugin("pubsub");
	stream.pep = {};

	stream:hook("pubsub/event", function(event)
		return stream:event("pep/"..event.node, { from = event.from, item = event.item.tags[1] } );
	end);

	function stream:hook_pep(node, callback, priority)
		local handlers = stream.events._handlers["pep/"..node];
		if not(handlers) or #handlers == 0 then
			stream:add_disco_feature(node.."+notify");
		end
		stream:hook("pep/"..node, callback, priority);
	end

	function stream:unhook_pep(node, callback)
		stream:unhook("pep/"..node, callback);
		local handlers = stream.events._handlers["pep/"..node];
		if not(handlers) or #handlers == 0 then
			stream:remove_disco_feature(node.."+notify");
		end
	end

	function stream:publish_pep(item, node, id)
		return stream.pubsub:service(nil):node(node or item.attr.xmlns):publish(id or "current", nil, item)
	end
end
 end)
package.preload['verse.plugins.adhoc'] = (function (...)
					local _ENV = _ENV;
					local function module(name, ...)
						local t = package.loaded[name] or _ENV[name] or { _NAME = name };
						package.loaded[name] = t;
						for i = 1, select("#", ...) do
							(select(i, ...))(t);
						end
						_ENV = t;
						_M = t;
						return t;
					end
				local verse = require "verse";
local adhoc = require "lib.adhoc";

local xmlns_commands = "http://jabber.org/protocol/commands";
local xmlns_data = "jabber:x:data";

local command_mt = {};
command_mt.__index = command_mt;

-- Table of commands we provide
local commands = {};

function verse.plugins.adhoc(stream)
	stream:add_plugin("disco");
	stream:add_disco_feature(xmlns_commands);

	function stream:query_commands(jid, callback)
		stream:disco_items(jid, xmlns_commands, function (items)
			stream:debug("adhoc list returned")
			local command_list = {};
			for _, item in ipairs(items) do
				command_list[item.node] = item.name;
			end
			stream:debug("adhoc calling callback")
			return callback(command_list);
		end);
	end

	function stream:execute_command(jid, command, callback)
		local cmd = setmetatable({
			stream = stream, jid = jid,
			command = command, callback = callback
		}, command_mt);
		return cmd:execute();
	end

	-- ACL checker for commands we provide
	local function has_affiliation(jid, aff)
		if not(aff) or aff == "user" then return true; end
		if type(aff) == "function" then
			return aff(jid);
		end
		-- TODO: Support 'roster', etc.
	end

	function stream:add_adhoc_command(name, node, handler, permission)
		commands[node] = adhoc.new(name, node, handler, permission);
		stream:add_disco_item({ jid = stream.jid, node = node, name = name }, xmlns_commands);
		return commands[node];
	end

	local function handle_command(stanza)
		local command_tag = stanza.tags[1];
		local node = command_tag.attr.node;

		local handler = commands[node];
		if not handler then return; end

		if not has_affiliation(stanza.attr.from, handler.permission) then
			stream:send(verse.error_reply(stanza, "auth", "forbidden", "You don't have permission to execute this command"):up()
			:add_child(handler:cmdtag("canceled")
				:tag("note", {type="error"}):text("You don't have permission to execute this command")));
			return true
		end

		-- User has permission now execute the command
		return adhoc.handle_cmd(handler, { send = function (d) return stream:send(d) end }, stanza);
	end

	stream:hook("iq/"..xmlns_commands, function (stanza)
		local type = stanza.attr.type;
		local name = stanza.tags[1].name;
		if type == "set" and name == "command" then
			return handle_command(stanza);
		end
	end);
end

function command_mt:_process_response(result)
	if result.attr.type == "error" then
		self.status = "canceled";
		self.callback(self, {});
		return;
	end
	local command = result:get_child("command", xmlns_commands);
	self.status = command.attr.status;
	self.sessionid = command.attr.sessionid;
	self.form = command:get_child("x", xmlns_data);
	self.note = command:get_child("note"); --FIXME handle multiple <note/>s
	self.callback(self);
end

-- Initial execution of a command
function command_mt:execute()
	local iq = verse.iq({ to = self.jid, type = "set" })
		:tag("command", { xmlns = xmlns_commands, node = self.command });
	self.stream:send_iq(iq, function (result)
		self:_process_response(result);
	end);
end

function command_mt:next(form)
	local iq = verse.iq({ to = self.jid, type = "set" })
		:tag("command", {
			xmlns = xmlns_commands,
			node = self.command,
			sessionid = self.sessionid
		});

	if form then iq:add_child(form); end

	self.stream:send_iq(iq, function (result)
		self:_process_response(result);
	end);
end
 end)
package.preload['verse.plugins.presence'] = (function (...)
					local _ENV = _ENV;
					local function module(name, ...)
						local t = package.loaded[name] or _ENV[name] or { _NAME = name };
						package.loaded[name] = t;
						for i = 1, select("#", ...) do
							(select(i, ...))(t);
						end
						_ENV = t;
						_M = t;
						return t;
					end
				local verse = require "verse";

function verse.plugins.presence(stream)
	stream.last_presence = nil;

	stream:hook("presence-out", function (presence)
		if not presence.attr.to then
			stream.last_presence = presence; -- Cache non-directed presence
		end
	end, 1);

	function stream:resend_presence()
		if self.last_presence then
			stream:send(self.last_presence);
		end
	end

	function stream:set_status(opts)
		local p = verse.presence();
		if type(opts) == "table" then
			if opts.show then
				p:tag("show"):text(opts.show):up();
			end
			if opts.priority or opts.prio then
				p:tag("priority"):text(tostring(opts.priority or opts.prio)):up();
			end
			if opts.status or opts.msg then
				p:tag("status"):text(opts.status or opts.msg):up();
			end
		elseif type(opts) == "string" then
			p:tag("status"):text(opts):up();
		end

		stream:send(p);
	end
end
 end)
package.preload['verse.plugins.private'] = (function (...)
					local _ENV = _ENV;
					local function module(name, ...)
						local t = package.loaded[name] or _ENV[name] or { _NAME = name };
						package.loaded[name] = t;
						for i = 1, select("#", ...) do
							(select(i, ...))(t);
						end
						_ENV = t;
						_M = t;
						return t;
					end
				local verse = require "verse";

-- Implements XEP-0049: Private XML Storage

local xmlns_private = "jabber:iq:private";

function verse.plugins.private(stream)
	function stream:private_set(name, xmlns, data, callback)
		local iq = verse.iq({ type = "set" })
			:tag("query", { xmlns = xmlns_private });
		if data then
			if data.name == name and data.attr and data.attr.xmlns == xmlns then
				iq:add_child(data);
			else
				iq:tag(name, { xmlns = xmlns })
					:add_child(data);
			end
		end
		self:send_iq(iq, callback);
	end

	function stream:private_get(name, xmlns, callback)
		self:send_iq(verse.iq({type="get"})
			:tag("query", { xmlns = xmlns_private })
				:tag(name, { xmlns = xmlns }),
			function (reply)
				if reply.attr.type == "result" then
					local query = reply:get_child("query", xmlns_private);
					local result = query:get_child(name, xmlns);
					callback(result);
				end
			end);
	end
end

 end)
package.preload['verse.plugins.roster'] = (function (...)
					local _ENV = _ENV;
					local function module(name, ...)
						local t = package.loaded[name] or _ENV[name] or { _NAME = name };
						package.loaded[name] = t;
						for i = 1, select("#", ...) do
							(select(i, ...))(t);
						end
						_ENV = t;
						_M = t;
						return t;
					end
				local verse = require "verse";
local bare_jid = require "util.jid".bare;

local xmlns_roster = "jabber:iq:roster";
local xmlns_rosterver = "urn:xmpp:features:rosterver";
local t_insert = table.insert;

function verse.plugins.roster(stream)
	local ver_supported = false;
	local roster = {
		items = {};
		ver = "";
		-- TODO:
		-- groups = {};
	};
	stream.roster = roster;

	stream:hook("stream-features", function(features_stanza)
		if features_stanza:get_child("ver", xmlns_rosterver) then
			ver_supported = true;
		end
	end);

	local function item_lua2xml(item_table)
		local xml_item = verse.stanza("item", { xmlns = xmlns_roster });
		for k, v in pairs(item_table) do
			if k ~= "groups" then
				xml_item.attr[k] = v;
			else
				for i = 1,#v do
					xml_item:tag("group"):text(v[i]):up();
				end
			end
		end
		return xml_item;
	end

	local function item_xml2lua(xml_item)
		local item_table = { };
		local groups = {};
		item_table.groups = groups;

		for k, v in pairs(xml_item.attr) do
			if k ~= "xmlns" then
				item_table[k] = v
			end
		end

		for group in xml_item:childtags("group") do
			t_insert(groups, group:get_text())
		end
		return item_table;
	end

	function roster:load(r)
		roster.ver, roster.items = r.ver, r.items;
	end

	function roster:dump()
		return {
			ver = roster.ver,
			items = roster.items,
		};
	end

	-- should this be add_contact(item, callback) instead?
	function roster:add_contact(jid, name, groups, callback)
		local item = { jid = jid, name = name, groups = groups };
		local stanza = verse.iq({ type = "set" })
			:tag("query", { xmlns = xmlns_roster })
				:add_child(item_lua2xml(item));
		stream:send_iq(stanza, function (reply)
			if not callback then return end
			if reply.attr.type == "result" then
				callback(true);
			else
				callback(nil, reply);
			end
		end);
	end
	-- What about subscriptions?

	function roster:delete_contact(jid, callback)
		jid = (type(jid) == "table" and jid.jid) or jid;
		local item = { jid = jid, subscription = "remove" }
		if not roster.items[jid] then return false, "item-not-found"; end
		stream:send_iq(verse.iq({ type = "set" })
			:tag("query", { xmlns = xmlns_roster })
				:add_child(item_lua2xml(item)),
			function (reply)
				if not callback then return end
				if reply.attr.type == "result" then
					callback(true);
				else
					callback(nil, reply);
				end
			end);
	end

	local function add_item(item) -- Takes one roster <item/>
		local roster_item = item_xml2lua(item);
		roster.items[roster_item.jid] = roster_item;
	end

	-- Private low level
	local function delete_item(jid)
		local deleted_item = roster.items[jid];
		roster.items[jid] = nil;
		return deleted_item;
	end

	function roster:fetch(callback)
		stream:send_iq(verse.iq({type="get"}):tag("query", { xmlns = xmlns_roster, ver = ver_supported and roster.ver or nil }),
			function (result)
				if result.attr.type == "result" then
					local query = result:get_child("query", xmlns_roster);
					if query then
						roster.items = {};
						for item in query:childtags("item") do
							add_item(item)
						end
						roster.ver = query.attr.ver or "";
					end
					callback(roster);
				else
					callback(nil, result);
				end
			end);
	end

	stream:hook("iq/"..xmlns_roster, function(stanza)
		local type, from = stanza.attr.type, stanza.attr.from;
		if type == "set" and (not from or from == bare_jid(stream.jid)) then
			local query = stanza:get_child("query", xmlns_roster);
			local item = query and query:get_child("item");
			if item then
				local event, target;
				local jid = item.attr.jid;
				if item.attr.subscription == "remove" then
					event = "removed"
					target = delete_item(jid);
				else
					event = roster.items[jid] and "changed" or "added";
					add_item(item)
					target = roster.items[jid];
				end
				roster.ver = query.attr.ver;
				if target then
					stream:event("roster/item-"..event, target);
				end
			-- TODO else return error? Events?
			end
			stream:send(verse.reply(stanza))
			return true;
		end
	end);
end
 end)
package.preload['verse.plugins.register'] = (function (...)
					local _ENV = _ENV;
					local function module(name, ...)
						local t = package.loaded[name] or _ENV[name] or { _NAME = name };
						package.loaded[name] = t;
						for i = 1, select("#", ...) do
							(select(i, ...))(t);
						end
						_ENV = t;
						_M = t;
						return t;
					end
				local verse = require "verse";

local xmlns_register = "jabber:iq:register";

function verse.plugins.register(stream)
	local function handle_features(features_stanza)
		if features_stanza:get_child("register", "http://jabber.org/features/iq-register") then
			local request = verse.iq({ to = stream.host_, type = "set" })
				:tag("query", { xmlns = xmlns_register })
					:tag("username"):text(stream.username):up()
					:tag("password"):text(stream.password):up();
			if stream.register_email then
				request:tag("email"):text(stream.register_email):up();
			end
			stream:send_iq(request, function (result)
				if result.attr.type == "result" then
					stream:event("registration-success");
				else
					local type, condition, text = result:get_error();
					stream:debug("Registration failed: %s", condition);
					stream:event("registration-failure", { type = type, condition = condition, text = text });
				end
			end);
		else
			stream:debug("In-band registration not offered by server");
			stream:event("registration-failure", { condition = "service-unavailable" });
		end
		stream:unhook("stream-features", handle_features);
		return true;
	end
	stream:hook("stream-features", handle_features, 310);
end
 end)
package.preload['verse.plugins.groupchat'] = (function (...)
					local _ENV = _ENV;
					local function module(name, ...)
						local t = package.loaded[name] or _ENV[name] or { _NAME = name };
						package.loaded[name] = t;
						for i = 1, select("#", ...) do
							(select(i, ...))(t);
						end
						_ENV = t;
						_M = t;
						return t;
					end
				local verse = require "verse";
local events = require "util.events";
local jid = require "util.jid";

local room_mt = {};
room_mt.__index = room_mt;

local xmlns_delay = "urn:xmpp:delay";
local xmlns_muc = "http://jabber.org/protocol/muc";

function verse.plugins.groupchat(stream)
	stream:add_plugin("presence")
	stream.rooms = {};

	stream:hook("stanza", function (stanza)
		local room_jid = jid.bare(stanza.attr.from);
		if not room_jid then return end
		local room = stream.rooms[room_jid]
		if not room and stanza.attr.to and room_jid then
			room = stream.rooms[stanza.attr.to.." "..room_jid]
		end
		if room and room.opts.source and stanza.attr.to ~= room.opts.source then return end
		if room then
			local nick = select(3, jid.split(stanza.attr.from));
			local body = stanza:get_child_text("body");
			local delay = stanza:get_child("delay", xmlns_delay);
			local event = {
				room_jid = room_jid;
				room = room;
				sender = room.occupants[nick];
				nick = nick;
				body = body;
				stanza = stanza;
				delay = (delay and delay.attr.stamp);
			};
			local ret = room:event(stanza.name, event);
			return ret or (stanza.name == "message") or nil;
		end
	end, 500);

	function stream:join_room(jid, nick, opts, password)
		if not nick then
			return false, "no nickname supplied"
		end
		opts = opts or {};
		local room = setmetatable(verse.eventable{
			stream = stream, jid = jid, nick = nick,
			subject = nil,
			occupants = {},
			opts = opts,
		}, room_mt);
		if opts.source then
			self.rooms[opts.source.." "..jid] = room;
		else
			self.rooms[jid] = room;
		end
		local occupants = room.occupants;
		room:hook("presence", function (presence)
			local nick = presence.nick or nick;
			if not occupants[nick] and presence.stanza.attr.type ~= "unavailable" then
				occupants[nick] = {
					nick = nick;
					jid = presence.stanza.attr.from;
					presence = presence.stanza;
				};
				local x = presence.stanza:get_child("x", xmlns_muc .. "#user");
				if x then
					local x_item = x:get_child("item");
					if x_item and x_item.attr then
						occupants[nick].real_jid    = x_item.attr.jid;
						occupants[nick].affiliation = x_item.attr.affiliation;
						occupants[nick].role        = x_item.attr.role;
					end
					--TODO Check for status 100?
				end
				if nick == room.nick then
					room.stream:event("groupchat/joined", room);
				else
					room:event("occupant-joined", occupants[nick]);
				end
			elseif occupants[nick] and presence.stanza.attr.type == "unavailable" then
				if nick == room.nick then
					room.stream:event("groupchat/left", room);
					if room.opts.source then
						self.rooms[room.opts.source.." "..jid] = nil;
					else
						self.rooms[jid] = nil;
					end
				else
					occupants[nick].presence = presence.stanza;
					room:event("occupant-left", occupants[nick]);
					occupants[nick] = nil;
				end
			end
		end);
		room:hook("message", function(event)
			local subject = event.stanza:get_child_text("subject");
			if not subject then return end
			subject = #subject > 0 and subject or nil;
			if subject ~= room.subject then
				local old_subject = room.subject;
				room.subject = subject;
				return room:event("subject-changed", { from = old_subject, to = subject, by = event.sender, event = event });
			end
		end, 2000);
		local join_st = verse.presence():tag("x",{xmlns = xmlns_muc}):reset();
		if password then
			join_st:get_child("x", xmlns_muc):tag("password"):text(password):reset();
		end
		self:event("pre-groupchat/joining", join_st);
		room:send(join_st)
		self:event("groupchat/joining", room);
		return room;
	end

	stream:hook("presence-out", function(presence)
		if not presence.attr.to then
			for _, room in pairs(stream.rooms) do
				room:send(presence);
			end
			presence.attr.to = nil;
		end
	end);
end

function room_mt:send(stanza)
	if stanza.name == "message" and not stanza.attr.type then
		stanza.attr.type = "groupchat";
	end
	if stanza.name == "presence" then
		stanza.attr.to = self.jid .."/"..self.nick;
	end
	if stanza.attr.type == "groupchat" or not stanza.attr.to then
		stanza.attr.to = self.jid;
	end
	if self.opts.source then
		stanza.attr.from = self.opts.source
	end
	self.stream:send(stanza);
end

function room_mt:send_message(text)
	self:send(verse.message():tag("body"):text(text));
end

function room_mt:set_subject(text)
	self:send(verse.message():tag("subject"):text(text));
end

function room_mt:leave(message)
	self.stream:event("groupchat/leaving", self);
	local presence = verse.presence({type="unavailable"});
	if message then
		presence:tag("status"):text(message);
	end
	self:send(presence);
end

function room_mt:admin_set(nick, what, value, reason)
	self:send(verse.iq({type="set"})
		:query(xmlns_muc .. "#admin")
			:tag("item", {nick = nick, [what] = value})
				:tag("reason"):text(reason or ""));
end

function room_mt:set_role(nick, role, reason)
	self:admin_set(nick, "role", role, reason);
end

function room_mt:set_affiliation(nick, affiliation, reason)
	self:admin_set(nick, "affiliation", affiliation, reason);
end

function room_mt:kick(nick, reason)
	self:set_role(nick, "none", reason);
end

function room_mt:ban(nick, reason)
	self:set_affiliation(nick, "outcast", reason);
end
 end)
package.preload['verse.plugins.vcard'] = (function (...)
					local _ENV = _ENV;
					local function module(name, ...)
						local t = package.loaded[name] or _ENV[name] or { _NAME = name };
						package.loaded[name] = t;
						for i = 1, select("#", ...) do
							(select(i, ...))(t);
						end
						_ENV = t;
						_M = t;
						return t;
					end
				local verse = require "verse";
local vcard = require "util.vcard";

local xmlns_vcard = "vcard-temp";

function verse.plugins.vcard(stream)
	function stream:get_vcard(jid, callback) --jid = nil for self
		stream:send_iq(verse.iq({to = jid, type="get"})
			:tag("vCard", {xmlns=xmlns_vcard}), callback and function(stanza)
				local vCard = stanza:get_child("vCard", xmlns_vcard);
				if stanza.attr.type == "result" and vCard then
					vCard = vcard.from_xep54(vCard)
					callback(vCard)
				else
					callback(false) -- FIXME add error
				end
			end or nil);
	end

	function stream:set_vcard(aCard, callback)
		local xCard;
		if type(aCard) == "table" and aCard.name then
			xCard = aCard;
		elseif type(aCard) == "string" then
			xCard = vcard.to_xep54(vcard.from_text(aCard)[1]);
		elseif type(aCard) == "table" then
			xCard = vcard.to_xep54(aCard);
			error("Converting a table to vCard not implemented")
		end
		if not xCard then return false end
		stream:debug("setting vcard to %s", tostring(xCard));
		stream:send_iq(verse.iq({type="set"})
			:add_child(xCard), callback);
	end
end
 end)
package.preload['verse.plugins.vcard_update'] = (function (...)
					local _ENV = _ENV;
					local function module(name, ...)
						local t = package.loaded[name] or _ENV[name] or { _NAME = name };
						package.loaded[name] = t;
						for i = 1, select("#", ...) do
							(select(i, ...))(t);
						end
						_ENV = t;
						_M = t;
						return t;
					end
				local verse = require "verse";

-- local xmlns_vcard = "vcard-temp";
local xmlns_vcard_update = "vcard-temp:x:update";

local sha1 = require("util.hashes").sha1;

local ok, fun = pcall(function()
	local unb64 = require("util.encodings").base64.decode;
	assert(unb64("SGVsbG8=") == "Hello")
	return unb64;
end);
if not ok then
	ok, fun = pcall(function() return require("mime").unb64; end);
	if not ok then
		error("Could not find a base64 decoder")
	end
end
local unb64 = fun;

function verse.plugins.vcard_update(stream)
	stream:add_plugin("vcard");
	stream:add_plugin("presence");


	local x_vcard_update;

	local function update_vcard_photo(vCard)
		local data;
		for i=1,#vCard do
			if vCard[i].name == "PHOTO" then
				data = vCard[i][1];
				break
			end
		end
		if data then
			local hash = sha1(unb64(data), true);
			x_vcard_update = verse.stanza("x", { xmlns = xmlns_vcard_update })
			:tag("photo"):text(hash);

			stream:resend_presence()
		else
			x_vcard_update = nil;
		end
	end


	--[[ TODO Complete this, it's probably broken.
	-- Maybe better to hook outgoing stanza?
	local _set_vcard = stream.set_vcard;
	function stream:set_vcard(vCard, callback)
		_set_vcard(vCard, function(event, ...)
			if event.attr.type == "result" then
				local vCard_ = response:get_child("vCard", xmlns_vcard);
				if vCard_ then
					update_vcard_photo(vCard_);
				end -- Or fetch it again? Seems wasteful, but if the server overrides stuff? :/
			end
			if callback then
				return callback(event, ...);
			end
		end);
	end
	--]]

	local initial_vcard_fetch_started;
	stream:hook("ready", function()
		if initial_vcard_fetch_started then return; end
		initial_vcard_fetch_started = true;
		-- if stream:jid_supports(nil, xmlns_vcard) then TODO this, correctly
		stream:get_vcard(nil, function(response)
			if response then
				update_vcard_photo(response)
			end
			stream:event("ready");
		end);
		return true;
	end, 3);

	stream:hook("presence-out", function(presence)
		if x_vcard_update and not presence:get_child("x", xmlns_vcard_update) then
			presence:add_child(x_vcard_update);
		end
	end, 10);

	--[[
	stream:hook("presence", function(presence)
			local x_vcard_update = presence:get_child("x", xmlns_vcard_update);
			local photo_hash = x_vcard_update and x_vcard_update:get_child("photo");
				:get_child_text("photo");
			if x_vcard_update then
				-- TODO Cache peoples avatars here
			end
	end);
	--]]
end
 end)
package.preload['verse.plugins.carbons'] = (function (...)
					local _ENV = _ENV;
					local function module(name, ...)
						local t = package.loaded[name] or _ENV[name] or { _NAME = name };
						package.loaded[name] = t;
						for i = 1, select("#", ...) do
							(select(i, ...))(t);
						end
						_ENV = t;
						_M = t;
						return t;
					end
				local verse = require "verse";

local xmlns_carbons = "urn:xmpp:carbons:2";
local xmlns_forward = "urn:xmpp:forward:0";
local os_time = os.time;
local parse_datetime = require "util.datetime".parse;
local bare_jid = require "util.jid".bare;

-- TODO Check disco for support

function verse.plugins.carbons(stream)
	local carbons = {};
	carbons.enabled = false;
	stream.carbons = carbons;

	function carbons:enable(callback)
		stream:send_iq(verse.iq{type="set"}
		:tag("enable", { xmlns = xmlns_carbons })
		, function(result)
			local success = result.attr.type == "result";
			if success then
				carbons.enabled = true;
			end
			if callback then
				callback(success);
			end
		end or nil);
	end

	function carbons:disable(callback)
		stream:send_iq(verse.iq{type="set"}
		:tag("disable", { xmlns = xmlns_carbons })
		, function(result)
			local success = result.attr.type == "result";
			if success then
				carbons.enabled = false;
			end
			if callback then
				callback(success);
			end
		end or nil);
	end

	local my_bare;
	stream:hook("bind-success", function()
		my_bare = bare_jid(stream.jid);
	end);

	stream:hook("message", function(stanza)
		local carbon = stanza:get_child(nil, xmlns_carbons);
		if stanza.attr.from == my_bare and carbon then
			local carbon_dir = carbon.name;
			local fwd = carbon:get_child("forwarded", xmlns_forward);
			local fwd_stanza = fwd and fwd:get_child("message", "jabber:client");
			local delay = fwd:get_child("delay", "urn:xmpp:delay");
			local stamp = delay and delay.attr.stamp;
			stamp = stamp and parse_datetime(stamp);
			if fwd_stanza then
				return stream:event("carbon", {
					dir = carbon_dir,
					stanza = fwd_stanza,
					timestamp = stamp or os_time(),
				});
			end
		end
	end, 1);
end
 end)
package.preload['verse.plugins.archive'] = (function (...)
					local _ENV = _ENV;
					local function module(name, ...)
						local t = package.loaded[name] or _ENV[name] or { _NAME = name };
						package.loaded[name] = t;
						for i = 1, select("#", ...) do
							(select(i, ...))(t);
						end
						_ENV = t;
						_M = t;
						return t;
					end
				-- This implements XEP-0313: Message Archive Management
-- http://xmpp.org/extensions/xep-0313.html
-- (ie not XEP-0136)

local verse = require "verse";
local st = require "util.stanza";
local xmlns_mam = "urn:xmpp:mam:2"
local xmlns_forward = "urn:xmpp:forward:0";
local xmlns_delay = "urn:xmpp:delay";
local uuid = require "util.uuid".generate;
local parse_datetime = require "util.datetime".parse;
local datetime = require "util.datetime".datetime;
local dataform = require"util.dataforms".new;
local rsm = require "util.rsm";
local NULL = {};

local query_form = dataform {
	{ name = "FORM_TYPE"; type = "hidden"; value = xmlns_mam; };
	{ name = "with"; type = "jid-single"; };
	{ name = "start"; type = "text-single" };
	{ name = "end"; type = "text-single"; };
};

function verse.plugins.archive(stream)
	function stream:query_archive(where, query_params, callback)
		local queryid = uuid();
		local query_st = st.iq{ type="set", to = where }
			:tag("query", { xmlns = xmlns_mam, queryid = queryid });


		local qstart, qend = tonumber(query_params["start"]), tonumber(query_params["end"]);
		query_params["start"] = qstart and datetime(qstart);
		query_params["end"] = qend and datetime(qend);

		query_st:add_child(query_form:form(query_params, "submit"));
		-- query_st:up();
		query_st:add_child(rsm.generate(query_params));

		local results = {};
		local function handle_archived_message(message)

			local result_tag = message:get_child("result", xmlns_mam);
			if result_tag and result_tag.attr.queryid == queryid then
				local forwarded = result_tag:get_child("forwarded", xmlns_forward);

				local id = result_tag.attr.id;
				local delay = forwarded:get_child("delay", xmlns_delay);
				local stamp = delay and parse_datetime(delay.attr.stamp) or nil;

				local message = forwarded:get_child("message", "jabber:client")

				results[#results+1] = { id = id, stamp = stamp, message = message };
				return true
			end
		end

		self:hook("message", handle_archived_message, 1);
		self:send_iq(query_st, function(reply)
			self:unhook("message", handle_archived_message);
			if reply.attr.type == "error" then
				self:warn(table.concat({reply:get_error()}, " "))
				callback(false, reply:get_error())
				return true;
			end
			local finished = reply:get_child("fin", xmlns_mam)
			if finished then
				local rset = rsm.get(finished);
				for k,v in pairs(rset or NULL) do results[k]=v; end
			end
			callback(results);
			return true
		end);
	end

	local default_attrs = {
		always = true, [true] = "always",
		never = false, [false] = "never",
		roster = "roster",
	}

	local function prefs_decode(stanza) -- from XML
		local prefs = {};
		local default = stanza.attr.default;

		if default then
			prefs[false] = default_attrs[default];
		end

		local always = stanza:get_child("always");
		if always then
			for rule in always:childtags("jid") do
				local jid = rule:get_text();
				prefs[jid] = true;
			end
		end

		local never = stanza:get_child("never");
		if never then
			for rule in never:childtags("jid") do
				local jid = rule:get_text();
				prefs[jid] = false;
			end
		end
		return prefs;
	end

	local function prefs_encode(prefs) -- into XML
		local default
		default, prefs[false] = prefs[false], nil;
		if default ~= nil then
			default = default_attrs[default];
		end
		local reply = st.stanza("prefs", { xmlns = xmlns_mam, default = default })
		local always = st.stanza("always");
		local never = st.stanza("never");
		for k,v in pairs(prefs) do
			(v and always or never):tag("jid"):text(k):up();
		end
		return reply:add_child(always):add_child(never);
	end

	function stream:archive_prefs_get(callback)
		self:send_iq(st.iq{ type="get" }:tag("prefs", { xmlns = xmlns_mam }),
		function(result)
			if result and result.attr.type == "result" and result.tags[1] then
				local prefs = prefs_decode(result.tags[1]);
				callback(prefs, result);
			else
				callback(nil, result);
			end
		end);
	end

	function stream:archive_prefs_set(prefs, callback)
		self:send_iq(st.iq{ type="set" }:add_child(prefs_encode(prefs)), callback);
	end
end
 end)
package.preload['util.http'] = (function (...)
					local _ENV = _ENV;
					local function module(name, ...)
						local t = package.loaded[name] or _ENV[name] or { _NAME = name };
						package.loaded[name] = t;
						for i = 1, select("#", ...) do
							(select(i, ...))(t);
						end
						_ENV = t;
						_M = t;
						return t;
					end
				-- Prosody IM
-- Copyright (C) 2013 Florian Zeitz
--
-- This project is MIT/X11 licensed. Please see the
-- COPYING file in the source package for more information.
--

local format, char = string.format, string.char;
local pairs, ipairs, tonumber = pairs, ipairs, tonumber;
local t_insert, t_concat = table.insert, table.concat;

local function urlencode(s)
	return s and (s:gsub("[^a-zA-Z0-9.~_-]", function (c) return format("%%%02x", c:byte()); end));
end
local function urldecode(s)
	return s and (s:gsub("%%(%x%x)", function (c) return char(tonumber(c,16)); end));
end

local function _formencodepart(s)
	return s and (s:gsub("%W", function (c)
		if c ~= " " then
			return format("%%%02x", c:byte());
		else
			return "+";
		end
	end));
end

local function formencode(form)
	local result = {};
	if form[1] then -- Array of ordered { name, value }
		for _, field in ipairs(form) do
			t_insert(result, _formencodepart(field.name).."=".._formencodepart(field.value));
		end
	else -- Unordered map of name -> value
		for name, value in pairs(form) do
			t_insert(result, _formencodepart(name).."=".._formencodepart(value));
		end
	end
	return t_concat(result, "&");
end

local function formdecode(s)
	if not s:match("=") then return urldecode(s); end
	local r = {};
	for k, v in s:gmatch("([^=&]*)=([^&]*)") do
		k, v = k:gsub("%+", "%%20"), v:gsub("%+", "%%20");
		k, v = urldecode(k), urldecode(v);
		t_insert(r, { name = k, value = v });
		r[k] = v;
	end
	return r;
end

local function contains_token(field, token)
	field = ","..field:gsub("[ \t]", ""):lower()..",";
	return field:find(","..token:lower()..",", 1, true) ~= nil;
end

return {
	urlencode = urlencode, urldecode = urldecode;
	formencode = formencode, formdecode = formdecode;
	contains_token = contains_token;
};
 end)
package.preload['net.http.parser'] = (function (...)
					local _ENV = _ENV;
					local function module(name, ...)
						local t = package.loaded[name] or _ENV[name] or { _NAME = name };
						package.loaded[name] = t;
						for i = 1, select("#", ...) do
							(select(i, ...))(t);
						end
						_ENV = t;
						_M = t;
						return t;
					end
				local tonumber = tonumber;
local assert = assert;
local t_insert, t_concat = table.insert, table.concat;
local url_parse = require "socket.url".parse;
local urldecode = require "util.http".urldecode;

local function preprocess_path(path)
	path = urldecode((path:gsub("//+", "/")));
	if path:sub(1,1) ~= "/" then
		path = "/"..path;
	end
	local level = 0;
	for component in path:gmatch("([^/]+)/") do
		if component == ".." then
			level = level - 1;
		elseif component ~= "." then
			level = level + 1;
		end
		if level < 0 then
			return nil;
		end
	end
	return path;
end

local httpstream = {};

function httpstream.new(success_cb, error_cb, parser_type, options_cb)
	local client = true;
	if not parser_type or parser_type == "server" then client = false; else assert(parser_type == "client", "Invalid parser type"); end
	local buf, buflen, buftable = {}, 0, true;
	local bodylimit = tonumber(options_cb and options_cb().body_size_limit) or 10*1024*1024;
	local buflimit = tonumber(options_cb and options_cb().buffer_size_limit) or bodylimit * 2;
	local chunked, chunk_size, chunk_start;
	local state = nil;
	local packet;
	local len;
	local have_body;
	local error;
	return {
		feed = function(_, data)
			if error then return nil, "parse has failed"; end
			if not data then -- EOF
				if buftable then buf, buftable = t_concat(buf), false; end
				if state and client and not len then -- reading client body until EOF
					packet.body = buf;
					success_cb(packet);
				elseif buf ~= "" then -- unexpected EOF
					error = true; return error_cb("unexpected-eof");
				end
				return;
			end
			if buftable then
				t_insert(buf, data);
			else
				buf = { buf, data };
				buftable = true;
			end
			buflen = buflen + #data;
			if buflen > buflimit then error = true; return error_cb("max-buffer-size-exceeded"); end
			while buflen > 0 do
				if state == nil then -- read request
					if buftable then buf, buftable = t_concat(buf), false; end
					local index = buf:find("\r\n\r\n", nil, true);
					if not index then return; end -- not enough data
					local method, path, httpversion, status_code, reason_phrase;
					local first_line;
					local headers = {};
					for line in buf:sub(1,index+1):gmatch("([^\r\n]+)\r\n") do -- parse request
						if first_line then
							local key, val = line:match("^([^%s:]+): *(.*)$");
							if not key then error = true; return error_cb("invalid-header-line"); end -- TODO handle multi-line and invalid headers
							key = key:lower();
							headers[key] = headers[key] and headers[key]..","..val or val;
						else
							first_line = line;
							if client then
								httpversion, status_code, reason_phrase = line:match("^HTTP/(1%.[01]) (%d%d%d) (.*)$");
								status_code = tonumber(status_code);
								if not status_code then error = true; return error_cb("invalid-status-line"); end
								have_body = not
									 ( (options_cb and options_cb().method == "HEAD")
									or (status_code == 204 or status_code == 304 or status_code == 301)
									or (status_code >= 100 and status_code < 200) );
							else
								method, path, httpversion = line:match("^(%w+) (%S+) HTTP/(1%.[01])$");
								if not method then error = true; return error_cb("invalid-status-line"); end
							end
						end
					end
					if not first_line then error = true; return error_cb("invalid-status-line"); end
					chunked = have_body and headers["transfer-encoding"] == "chunked";
					len = tonumber(headers["content-length"]); -- TODO check for invalid len
					if len and len > bodylimit then error = true; return error_cb("content-length-limit-exceeded"); end
					if client then
						-- FIXME handle '100 Continue' response (by skipping it)
						if not have_body then len = 0; end
						packet = {
							code = status_code;
							httpversion = httpversion;
							headers = headers;
							body = have_body and "" or nil;
							-- COMPAT the properties below are deprecated
							responseversion = httpversion;
							responseheaders = headers;
						};
					else
						local parsed_url;
						if path:byte() == 47 then -- starts with /
							local _path, _query = path:match("([^?]*).?(.*)");
							if _query == "" then _query = nil; end
							parsed_url = { path = _path, query = _query };
						else
							parsed_url = url_parse(path);
							if not(parsed_url and parsed_url.path) then error = true; return error_cb("invalid-url"); end
						end
						path = preprocess_path(parsed_url.path);
						headers.host = parsed_url.host or headers.host;

						len = len or 0;
						packet = {
							method = method;
							url = parsed_url;
							path = path;
							httpversion = httpversion;
							headers = headers;
							body = nil;
						};
					end
					buf = buf:sub(index + 4);
					buflen = #buf;
					state = true;
				end
				if state then -- read body
					if client then
						if chunked then
							if chunk_start and buflen - chunk_start - 2 < chunk_size then
								return;
							end -- not enough data
							if buftable then buf, buftable = t_concat(buf), false; end
							if not buf:find("\r\n", nil, true) then
								return;
							end -- not enough data
							if not chunk_size then
								chunk_size, chunk_start = buf:match("^(%x+)[^\r\n]*\r\n()");
								chunk_size = chunk_size and tonumber(chunk_size, 16);
								if not chunk_size then error = true; return error_cb("invalid-chunk-size"); end
							end
							if chunk_size == 0 and buf:find("\r\n\r\n", chunk_start-2, true) then
								state, chunk_size = nil, nil;
								buf = buf:gsub("^.-\r\n\r\n", ""); -- This ensure extensions and trailers are stripped
								success_cb(packet);
							elseif buflen - chunk_start - 2 >= chunk_size then -- we have a chunk
								packet.body = packet.body..buf:sub(chunk_start, chunk_start + (chunk_size-1));
								buf = buf:sub(chunk_start + chunk_size + 2);
								buflen = buflen - (chunk_start + chunk_size + 2 - 1);
								chunk_size, chunk_start = nil, nil;
							else -- Partial chunk remaining
								break;
							end
						elseif len and buflen >= len then
							if buftable then buf, buftable = t_concat(buf), false; end
							if packet.code == 101 then
								packet.body, buf, buflen, buftable = buf, {}, 0, true;
							else
								packet.body, buf = buf:sub(1, len), buf:sub(len + 1);
								buflen = #buf;
							end
							state = nil; success_cb(packet);
						else
							break;
						end
					elseif buflen >= len then
						if buftable then buf, buftable = t_concat(buf), false; end
						packet.body, buf = buf:sub(1, len), buf:sub(len + 1);
						buflen = #buf;
						state = nil; success_cb(packet);
					else
						break;
					end
				end
			end
		end;
	};
end

return httpstream;
 end)
package.preload['net.http'] = (function (...)
					local _ENV = _ENV;
					local function module(name, ...)
						local t = package.loaded[name] or _ENV[name] or { _NAME = name };
						package.loaded[name] = t;
						for i = 1, select("#", ...) do
							(select(i, ...))(t);
						end
						_ENV = t;
						_M = t;
						return t;
					end
				-- Prosody IM
-- Copyright (C) 2008-2010 Matthew Wild
-- Copyright (C) 2008-2010 Waqas Hussain
--
-- This project is MIT/X11 licensed. Please see the
-- COPYING file in the source package for more information.
--

local b64 = require "util.encodings".base64.encode;
local url = require "socket.url"
local httpstream_new = require "net.http.parser".new;
local util_http = require "util.http";
local events = require "util.events";
local verify_identity = require"util.x509".verify_identity;

local ssl_available = pcall(require, "ssl");

local server = require "net.server"

local t_insert, t_concat = table.insert, table.concat;
local pairs = pairs;
local tonumber, tostring, xpcall, traceback =
      tonumber, tostring, xpcall, debug.traceback;
local error = error
local setmetatable = setmetatable;

local log = require "util.logger".init("http");

local _ENV = nil;

local requests = {}; -- Open requests

local function make_id(req) return (tostring(req):match("%x+$")); end

local listener = { default_port = 80, default_mode = "*a" };

function listener.onconnect(conn)
	local req = requests[conn];

	-- Validate certificate
	if not req.insecure and conn:ssl() then
		local sock = conn:socket();
		local chain_valid = sock.getpeerverification and sock:getpeerverification();
		if not chain_valid then
			req.callback("certificate-chain-invalid", 0, req);
			req.callback = nil;
			conn:close();
			return;
		end
		local cert = sock.getpeercertificate and sock:getpeercertificate();
		if not cert or not verify_identity(req.host, false, cert) then
			req.callback("certificate-verify-failed", 0, req);
			req.callback = nil;
			conn:close();
			return;
		end
	end

	-- Send the request
	local request_line = { req.method or "GET", " ", req.path, " HTTP/1.1\r\n" };
	if req.query then
		t_insert(request_line, 4, "?"..req.query);
	end

	conn:write(t_concat(request_line));
	local t = { [2] = ": ", [4] = "\r\n" };
	for k, v in pairs(req.headers) do
		t[1], t[3] = k, v;
		conn:write(t_concat(t));
	end
	conn:write("\r\n");

	if req.body then
		conn:write(req.body);
	end
end

function listener.onincoming(conn, data)
	local request = requests[conn];

	if not request then
		log("warn", "Received response from connection %s with no request attached!", tostring(conn));
		return;
	end

	if data and request.reader then
		request:reader(data);
	end
end

function listener.ondisconnect(conn, err)
	local request = requests[conn];
	if request and request.conn then
		request:reader(nil, err or "closed");
	end
	requests[conn] = nil;
end

function listener.ondetach(conn)
	requests[conn] = nil;
end

local function destroy_request(request)
	if request.conn then
		request.conn = nil;
		request.handler:close()
	end
end

local function request_reader(request, data, err)
	if not request.parser then
		local function error_cb(reason)
			if request.callback then
				request.callback(reason or "connection-closed", 0, request);
				request.callback = nil;
			end
			destroy_request(request);
		end

		if not data then
			error_cb(err);
			return;
		end

		local function success_cb(r)
			if request.callback then
				request.callback(r.body, r.code, r, request);
				request.callback = nil;
			end
			destroy_request(request);
		end
		local function options_cb()
			return request;
		end
		request.parser = httpstream_new(success_cb, error_cb, "client", options_cb);
	end
	request.parser:feed(data);
end

local function handleerr(err) log("error", "Traceback[http]: %s", traceback(tostring(err), 2)); end
local function log_if_failed(id, ret, ...)
	if not ret then
		log("error", "Request '%s': error in callback: %s", id, tostring((...)));
	end
	return ...;
end

local function request(self, u, ex, callback)
	local req = url.parse(u);
	req.url = u;

	if not (req and req.host) then
		callback("invalid-url", 0, req);
		return nil, "invalid-url";
	end

	if not req.path then
		req.path = "/";
	end

	req.id = ex and ex.id or make_id(req);

	do
		local event = { http = self, url = u, request = req, options = ex, callback = callback };
		local ret = self.events.fire_event("pre-request", event);
		if ret then
			return ret;
		end
		req, u, ex, callback = event.request, event.url, event.options, event.callback;
	end

	local method, headers, body;

	local host, port = req.host, req.port;
	local host_header = host;
	if (port == "80" and req.scheme == "http")
	or (port == "443" and req.scheme == "https") then
		port = nil;
	elseif port then
		host_header = host_header..":"..port;
	end

	headers = {
		["Host"] = host_header;
		["User-Agent"] = "Prosody XMPP Server";
	};

	if req.userinfo then
		headers["Authorization"] = "Basic "..b64(req.userinfo);
	end

	if ex then
		req.onlystatus = ex.onlystatus;
		body = ex.body;
		if body then
			method = "POST";
			headers["Content-Length"] = tostring(#body);
			headers["Content-Type"] = "application/x-www-form-urlencoded";
		end
		if ex.method then method = ex.method; end
		if ex.headers then
			for k, v in pairs(ex.headers) do
				headers[k] = v;
			end
		end
		req.insecure = ex.insecure;
	end

	log("debug", "Making %s %s request '%s' to %s", req.scheme:upper(), method or "GET", req.id, (ex and ex.suppress_url and host_header) or u);

	-- Attach to request object
	req.method, req.headers, req.body = method, headers, body;

	local using_https = req.scheme == "https";
	if using_https and not ssl_available then
		error("SSL not available, unable to contact https URL");
	end
	local port_number = port and tonumber(port) or (using_https and 443 or 80);

	local sslctx = false;
	if using_https then
		sslctx = ex and ex.sslctx or self.options and self.options.sslctx;
	end

	local handler, conn = server.addclient(host, port_number, listener, "*a", sslctx)
	if not handler then
		self.events.fire_event("request-connection-error", { http = self, request = req, url = u, err = conn });
		callback(conn, 0, req);
		return nil, conn;
	end
	req.handler, req.conn = handler, conn
	req.write = function (...) return req.handler:write(...); end

	req.callback = function (content, code, response, request)
		do
			local event = { http = self, url = u, request = req, response = response, content = content, code = code, callback = callback };
			self.events.fire_event("response", event);
			content, code, response = event.content, event.code, event.response;
		end

		log("debug", "Request '%s': Calling callback, status %s", req.id, code or "---");
		return log_if_failed(req.id, xpcall(function () return callback(content, code, response, request) end, handleerr));
	end
	req.reader = request_reader;
	req.state = "status";

	requests[req.handler] = req;

	self.events.fire_event("request", { http = self, request = req, url = u });
	return req;
end

local function new(options)
	local http = {
		options = options;
		request = request;
		new = options and function (new_options)
			return new(setmetatable(new_options, { __index = options }));
		end or new;
		events = events.new();
	};
	return http;
end

local default_http = new({
	sslctx = { mode = "client", protocol = "sslv23", options = { "no_sslv2", "no_sslv3" } };
});

return {
	request = function (u, ex, callback)
		return default_http:request(u, ex, callback);
	end;
	default = default_http;
	new = new;
	events = default_http.events;
	-- COMPAT
	urlencode = util_http.urlencode;
	urldecode = util_http.urldecode;
	formencode = util_http.formencode;
	formdecode = util_http.formdecode;
};
 end)
package.preload['util.x509'] = (function (...)
					local _ENV = _ENV;
					local function module(name, ...)
						local t = package.loaded[name] or _ENV[name] or { _NAME = name };
						package.loaded[name] = t;
						for i = 1, select("#", ...) do
							(select(i, ...))(t);
						end
						_ENV = t;
						_M = t;
						return t;
					end
				-- Prosody IM
-- Copyright (C) 2010 Matthew Wild
-- Copyright (C) 2010 Paul Aurich
--
-- This project is MIT/X11 licensed. Please see the
-- COPYING file in the source package for more information.
--

-- TODO: I feel a fair amount of this logic should be integrated into Luasec,
-- so that everyone isn't re-inventing the wheel.  Dependencies on
-- IDN libraries complicate that.


-- [TLS-CERTS] - http://tools.ietf.org/html/rfc6125
-- [XMPP-CORE] - http://tools.ietf.org/html/rfc6120
-- [SRV-ID]    - http://tools.ietf.org/html/rfc4985
-- [IDNA]      - http://tools.ietf.org/html/rfc5890
-- [LDAP]      - http://tools.ietf.org/html/rfc4519
-- [PKIX]      - http://tools.ietf.org/html/rfc5280

local nameprep = require "util.encodings".stringprep.nameprep;
local idna_to_ascii = require "util.encodings".idna.to_ascii;
local base64 = require "util.encodings".base64;
local log = require "util.logger".init("x509");
local s_format = string.format;

local _ENV = nil;

local oid_commonname = "2.5.4.3"; -- [LDAP] 2.3
local oid_subjectaltname = "2.5.29.17"; -- [PKIX] 4.2.1.6
local oid_xmppaddr = "1.3.6.1.5.5.7.8.5"; -- [XMPP-CORE]
local oid_dnssrv   = "1.3.6.1.5.5.7.8.7"; -- [SRV-ID]

-- Compare a hostname (possibly international) with asserted names
-- extracted from a certificate.
-- This function follows the rules laid out in
-- sections 6.4.1 and 6.4.2 of [TLS-CERTS]
--
-- A wildcard ("*") all by itself is allowed only as the left-most label
local function compare_dnsname(host, asserted_names)
	-- TODO: Sufficient normalization?  Review relevant specs.
	local norm_host = idna_to_ascii(host)
	if norm_host == nil then
		log("info", "Host %s failed IDNA ToASCII operation", host)
		return false
	end

	norm_host = norm_host:lower()

	local host_chopped = norm_host:gsub("^[^.]+%.", "") -- everything after the first label

	for i=1,#asserted_names do
		local name = asserted_names[i]
		if norm_host == name:lower() then
			log("debug", "Cert dNSName %s matched hostname", name);
			return true
		end

		-- Allow the left most label to be a "*"
		if name:match("^%*%.") then
			local rest_name = name:gsub("^[^.]+%.", "")
			if host_chopped == rest_name:lower() then
				log("debug", "Cert dNSName %s matched hostname", name);
				return true
			end
		end
	end

	return false
end

-- Compare an XMPP domain name with the asserted id-on-xmppAddr
-- identities extracted from a certificate.  Both are UTF8 strings.
--
-- Per [XMPP-CORE], matches against asserted identities don't include
-- wildcards, so we just do a normalize on both and then a string comparison
--
-- TODO: Support for full JIDs?
local function compare_xmppaddr(host, asserted_names)
	local norm_host = nameprep(host)

	for i=1,#asserted_names do
		local name = asserted_names[i]

		-- We only want to match against bare domains right now, not
		-- those crazy full-er JIDs.
		if name:match("[@/]") then
			log("debug", "Ignoring xmppAddr %s because it's not a bare domain", name)
		else
			local norm_name = nameprep(name)
			if norm_name == nil then
				log("info", "Ignoring xmppAddr %s, failed nameprep!", name)
			else
				if norm_host == norm_name then
					log("debug", "Cert xmppAddr %s matched hostname", name)
					return true
				end
			end
		end
	end

	return false
end

-- Compare a host + service against the asserted id-on-dnsSRV (SRV-ID)
-- identities extracted from a certificate.
--
-- Per [SRV-ID], the asserted identities will be encoded in ASCII via ToASCII.
-- Comparison is done case-insensitively, and a wildcard ("*") all by itself
-- is allowed only as the left-most non-service label.
local function compare_srvname(host, service, asserted_names)
	local norm_host = idna_to_ascii(host)
	if norm_host == nil then
		log("info", "Host %s failed IDNA ToASCII operation", host);
		return false
	end

	-- Service names start with a "_"
	if service:match("^_") == nil then service = "_"..service end

	norm_host = norm_host:lower();
	local host_chopped = norm_host:gsub("^[^.]+%.", "") -- everything after the first label

	for i=1,#asserted_names do
		local asserted_service, name = asserted_names[i]:match("^(_[^.]+)%.(.*)");
		if service == asserted_service then
			if norm_host == name:lower() then
				log("debug", "Cert SRVName %s matched hostname", name);
				return true;
			end

			-- Allow the left most label to be a "*"
			if name:match("^%*%.") then
				local rest_name = name:gsub("^[^.]+%.", "")
				if host_chopped == rest_name:lower() then
					log("debug", "Cert SRVName %s matched hostname", name)
					return true
				end
			end
			if norm_host == name:lower() then
				log("debug", "Cert SRVName %s matched hostname", name);
				return true
			end
		end
	end

	return false
end

local function verify_identity(host, service, cert)
	if cert.setencode then
		cert:setencode("utf8");
	end
	local ext = cert:extensions()
	if ext[oid_subjectaltname] then
		local sans = ext[oid_subjectaltname];

		-- Per [TLS-CERTS] 6.3, 6.4.4, "a client MUST NOT seek a match for a
		-- reference identifier if the presented identifiers include a DNS-ID
		-- SRV-ID, URI-ID, or any application-specific identifier types"
		local had_supported_altnames = false

		if sans[oid_xmppaddr] then
			had_supported_altnames = true
			if service == "_xmpp-client" or service == "_xmpp-server" then
				if compare_xmppaddr(host, sans[oid_xmppaddr]) then return true end
			end
		end

		if sans[oid_dnssrv] then
			had_supported_altnames = true
			-- Only check srvNames if the caller specified a service
			if service and compare_srvname(host, service, sans[oid_dnssrv]) then return true end
		end

		if sans["dNSName"] then
			had_supported_altnames = true
			if compare_dnsname(host, sans["dNSName"]) then return true end
		end

		-- We don't need URIs, but [TLS-CERTS] is clear.
		if sans["uniformResourceIdentifier"] then
			had_supported_altnames = true
		end

		if had_supported_altnames then return false end
	end

	-- Extract a common name from the certificate, and check it as if it were
	-- a dNSName subjectAltName (wildcards may apply for, and receive,
	-- cat treats)
	--
	-- Per [TLS-CERTS] 1.8, a CN-ID is the Common Name from a cert subject
	-- which has one and only one Common Name
	local subject = cert:subject()
	local cn = nil
	for i=1,#subject do
		local dn = subject[i]
		if dn["oid"] == oid_commonname then
			if cn then
				log("info", "Certificate has multiple common names")
				return false
			end

			cn = dn["value"];
		end
	end

	if cn then
		-- Per [TLS-CERTS] 6.4.4, follow the comparison rules for dNSName SANs.
		return compare_dnsname(host, { cn })
	end

	-- If all else fails, well, why should we be any different?
	return false
end

local pat = "%-%-%-%-%-BEGIN ([A-Z ]+)%-%-%-%-%-\r?\n"..
"([0-9A-Za-z+/=\r\n]*)\r?\n%-%-%-%-%-END %1%-%-%-%-%-";

local function pem2der(pem)
	local typ, data = pem:match(pat);
	if typ and data then
		return base64.decode(data), typ;
	end
end

local wrap = ('.'):rep(64);
local envelope = "-----BEGIN %s-----\n%s\n-----END %s-----\n"

local function der2pem(data, typ)
	typ = typ and typ:upper() or "CERTIFICATE";
	data = base64.encode(data);
	return s_format(envelope, typ, data:gsub(wrap, '%0\n', (#data-1)/64), typ);
end

return {
	verify_identity = verify_identity;
	pem2der = pem2der;
	der2pem = der2pem;
};
 end)
package.preload['verse.bosh'] = (function (...)
					local _ENV = _ENV;
					local function module(name, ...)
						local t = package.loaded[name] or _ENV[name] or { _NAME = name };
						package.loaded[name] = t;
						for i = 1, select("#", ...) do
							(select(i, ...))(t);
						end
						_ENV = t;
						_M = t;
						return t;
					end
				
local new_xmpp_stream = require "util.xmppstream".new;
local st = require "util.stanza";
require "net.httpclient_listener"; -- Required for net.http to work
local http = require "net.http";

local stream_mt = setmetatable({}, { __index = verse.stream_mt });
stream_mt.__index = stream_mt;

local xmlns_stream = "http://etherx.jabber.org/streams";
local xmlns_bosh = "http://jabber.org/protocol/httpbind";

local reconnect_timeout = 5;

function verse.new_bosh(logger, url)
	local stream = {
		bosh_conn_pool = {};
		bosh_waiting_requests = {};
		bosh_rid = math.random(1,999999);
		bosh_outgoing_buffer = {};
		bosh_url = url;
		conn = {};
	};
	function stream:reopen()
		self.bosh_need_restart = true;
		self:flush();
	end
	local conn = verse.new(logger, stream);
	return setmetatable(conn, stream_mt);
end

function stream_mt:connect()
	self:_send_session_request();
end

function stream_mt:send(data)
	self:debug("Putting into BOSH send buffer: %s", tostring(data));
	self.bosh_outgoing_buffer[#self.bosh_outgoing_buffer+1] = st.clone(data);
	self:flush(); --TODO: Optimize by doing this on next tick (give a chance for data to buffer)
end

function stream_mt:flush()
	if self.connected
	and #self.bosh_waiting_requests < self.bosh_max_requests
	and (#self.bosh_waiting_requests == 0
		or #self.bosh_outgoing_buffer > 0
		or self.bosh_need_restart) then
		self:debug("Flushing...");
		local payload = self:_make_body();
		local buffer = self.bosh_outgoing_buffer;
		for i, stanza in ipairs(buffer) do
			payload:add_child(stanza);
			buffer[i] = nil;
		end
		self:_make_request(payload);
	else
		self:debug("Decided not to flush.");
	end
end

function stream_mt:_make_request(payload)
	local request, err = http.request(self.bosh_url, { body = tostring(payload) }, function (response, code, request)
		if code ~= 0 then
			self.inactive_since = nil;
			return self:_handle_response(response, code, request);
		end

		-- Connection issues, we need to retry this request
		local time = os.time();
		if not self.inactive_since then
			self.inactive_since = time; -- So we know when it is time to give up
		elseif time - self.inactive_since > self.bosh_max_inactivity then
			return self:_disconnected();
		else
			self:debug("%d seconds left to reconnect, retrying in %d seconds...",
				self.bosh_max_inactivity - (time - self.inactive_since), reconnect_timeout);
		end

		-- Set up reconnect timer
		timer.add_task(reconnect_timeout, function ()
			self:debug("Retrying request...");
			-- Remove old request
			for i, waiting_request in ipairs(self.bosh_waiting_requests) do
				if waiting_request == request then
					table.remove(self.bosh_waiting_requests, i);
					break;
				end
			end
			self:_make_request(payload);
		end);
	end);
	if request then
		table.insert(self.bosh_waiting_requests, request);
	else
		self:warn("Request failed instantly: %s", err);
	end
end

function stream_mt:_disconnected()
	self.connected = nil;
	self:event("disconnected");
end

function stream_mt:_send_session_request()
	local body = self:_make_body();

	-- XEP-0124
	body.attr.hold = "1";
	body.attr.wait = "60";
	body.attr["xml:lang"] = "en";
	body.attr.ver = "1.6";

	-- XEP-0206
	body.attr.from = self.jid;
	body.attr.to = self.host;
	body.attr.secure = 'true';

	http.request(self.bosh_url, { body = tostring(body) }, function (response, code)
		if code == 0 then
			-- Failed to connect
			return self:_disconnected();
		end
		-- Handle session creation response
		local payload = self:_parse_response(response)
		if not payload then
			self:warn("Invalid session creation response");
			self:_disconnected();
			return;
		end
		self.bosh_sid = payload.attr.sid; -- Session id
		self.bosh_wait = tonumber(payload.attr.wait); -- How long the server may hold connections for
		self.bosh_hold = tonumber(payload.attr.hold); -- How many connections the server may hold
		self.bosh_max_inactivity = tonumber(payload.attr.inactivity); -- Max amount of time with no connections
		self.bosh_max_requests = tonumber(payload.attr.requests) or self.bosh_hold; -- Max simultaneous requests we can make
		self.connected = true;
		self:event("connected");
		self:_handle_response_payload(payload);
	end);
end

function stream_mt:_handle_response(response, code, request)
	if self.bosh_waiting_requests[1] ~= request then
		self:warn("Server replied to request that wasn't the oldest");
		for i, waiting_request in ipairs(self.bosh_waiting_requests) do
			if waiting_request == request then
				self.bosh_waiting_requests[i] = nil;
				break;
			end
		end
	else
		table.remove(self.bosh_waiting_requests, 1);
	end
	local payload = self:_parse_response(response);
	if payload then
		self:_handle_response_payload(payload);
	end
	self:flush();
end

function stream_mt:_handle_response_payload(payload)
	local stanzas = payload.tags;
	for i = 1, #stanzas do
		local stanza = stanzas[i];
		if stanza.attr.xmlns == xmlns_stream then
			self:event("stream-"..stanza.name, stanza);
		elseif stanza.attr.xmlns then
			self:event("stream/"..stanza.attr.xmlns, stanza);
		else
			self:event("stanza", stanza);
		end
	end
	if payload.attr.type == "terminate" then
		self:_disconnected({reason = payload.attr.condition});
	end
end

local stream_callbacks = {
	stream_ns = "http://jabber.org/protocol/httpbind", stream_tag = "body",
	default_ns = "jabber:client",
	streamopened = function (session, attr) session.notopen = nil; session.payload = verse.stanza("body", attr); return true; end;
	handlestanza = function (session, stanza) session.payload:add_child(stanza); end;
};
function stream_mt:_parse_response(response)
	self:debug("Parsing response: %s", response);
	if response == nil then
		self:debug("%s", debug.traceback());
		self:_disconnected();
		return;
	end
	local session = { notopen = true, stream = self };
	local stream = new_xmpp_stream(session, stream_callbacks);
	stream:feed(response);
	return session.payload;
end

function stream_mt:_make_body()
	self.bosh_rid = self.bosh_rid + 1;
	local body = verse.stanza("body", {
		xmlns = xmlns_bosh;
		content = "text/xml; charset=utf-8";
		sid = self.bosh_sid;
		rid = self.bosh_rid;
	});
	if self.bosh_need_restart then
		self.bosh_need_restart = nil;
		body.attr.restart = 'true';
	end
	return body;
end
 end)
package.preload['verse.client'] = (function (...)
					local _ENV = _ENV;
					local function module(name, ...)
						local t = package.loaded[name] or _ENV[name] or { _NAME = name };
						package.loaded[name] = t;
						for i = 1, select("#", ...) do
							(select(i, ...))(t);
						end
						_ENV = t;
						_M = t;
						return t;
					end
				local verse = require "verse";
local stream = verse.stream_mt;

local jid_split = require "util.jid".split;
local adns = require "net.adns";
local st = require "util.stanza";

-- Shortcuts to save having to load util.stanza
verse.message, verse.presence, verse.iq, verse.stanza, verse.reply, verse.error_reply =
	st.message, st.presence, st.iq, st.stanza, st.reply, st.error_reply;

local new_xmpp_stream = require "util.xmppstream".new;

local xmlns_stream = "http://etherx.jabber.org/streams";

local function compare_srv_priorities(a,b)
	return a.priority < b.priority or (a.priority == b.priority and a.weight > b.weight);
end

local stream_callbacks = {
	stream_ns = xmlns_stream,
	stream_tag = "stream",
	 default_ns = "jabber:client" };

function stream_callbacks.streamopened(stream, attr)
	stream.stream_id = attr.id;
	if not stream:event("opened", attr) then
		stream.notopen = nil;
	end
	return true;
end

function stream_callbacks.streamclosed(stream)
	stream.notopen = true;
	if not stream.closed then
		stream:send("</stream:stream>");
		stream.closed = true;
	end
	stream:event("closed");
	return stream:close("stream closed")
end

function stream_callbacks.handlestanza(stream, stanza)
	if stanza.attr.xmlns == xmlns_stream then
		return stream:event("stream-"..stanza.name, stanza);
	elseif stanza.attr.xmlns then
		return stream:event("stream/"..stanza.attr.xmlns, stanza);
	end

	return stream:event("stanza", stanza);
end

function stream_callbacks.error(stream, e, stanza)
	if stream:event(e, stanza) == nil then
		if stanza then
			local err = stanza:get_child(nil, "urn:ietf:params:xml:ns:xmpp-streams");
			local text = stanza:get_child_text("text", "urn:ietf:params:xml:ns:xmpp-streams");
			error(err.name..(text and ": "..text or ""));
		else
			error(stanza and stanza.name or e or "unknown-error");
		end
	end
end

function stream:reset()
	if self.stream then
		self.stream:reset();
	else
		self.stream = new_xmpp_stream(self, stream_callbacks);
	end
	self.notopen = true;
	return true;
end

function stream:connect_client(jid, pass)
	self.jid, self.password = jid, pass;
	self.username, self.host, self.resource = jid_split(jid);

	-- Required XMPP features
	self:add_plugin("tls");
	self:add_plugin("sasl");
	self:add_plugin("bind");
	self:add_plugin("session");

	function self.data(conn, data)
		local ok, err = self.stream:feed(data);
		if ok then return; end
		self:debug("Received invalid XML (%s) %d bytes: %s", tostring(err), #data, data:sub(1, 300):gsub("[\r\n]+", " "));
		self:close("xml-not-well-formed");
	end

	self:hook("connected", function () self:reopen(); end);
	self:hook("incoming-raw", function (data) return self.data(self.conn, data); end);

	self.curr_id = 0;

	self.tracked_iqs = {};
	self:hook("stanza", function (stanza)
		local id, type = stanza.attr.id, stanza.attr.type;
		if id and stanza.name == "iq" and (type == "result" or type == "error") and self.tracked_iqs[id] then
			self.tracked_iqs[id](stanza);
			self.tracked_iqs[id] = nil;
			return true;
		end
	end);

	self:hook("stanza", function (stanza)
		local ret;
		if stanza.attr.xmlns == nil or stanza.attr.xmlns == "jabber:client" then
			if stanza.name == "iq" and (stanza.attr.type == "get" or stanza.attr.type == "set") then
				local xmlns = stanza.tags[1] and stanza.tags[1].attr.xmlns;
				if xmlns then
					ret = self:event("iq/"..xmlns, stanza);
					if not ret then
						ret = self:event("iq", stanza);
					end
				end
				if ret == nil then
					self:send(verse.error_reply(stanza, "cancel", "service-unavailable"));
					return true;
				end
			else
				ret = self:event(stanza.name, stanza);
			end
		end
		return ret;
	end, -1);

	self:hook("outgoing", function (data)
		if data.name then
			self:event("stanza-out", data);
		end
	end);

	self:hook("stanza-out", function (stanza)
		if not stanza.attr.xmlns then
			self:event(stanza.name.."-out", stanza);
		end
	end);

	local function stream_ready()
		self:event("ready");
	end
	self:hook("session-success", stream_ready, -1)
	self:hook("bind-success", stream_ready, -1);

	local _base_close = self.close;
	function self:close(reason)
		self.close = _base_close;
		if not self.closed then
			self:send("</stream:stream>");
			self.closed = true;
		else
			return self:close(reason);
		end
	end

	local function start_connect()
		-- Initialise connection
		self:connect(self.connect_host or self.host, self.connect_port or 5222);
	end

	if not (self.connect_host or self.connect_port) then
		-- Look up SRV records
		adns.lookup(function (answer)
			if answer then
				local srv_hosts = {};
				self.srv_hosts = srv_hosts;
				for _, record in ipairs(answer) do
					table.insert(srv_hosts, record.srv);
				end
				table.sort(srv_hosts, compare_srv_priorities);

				local srv_choice = srv_hosts[1];
				self.srv_choice = 1;
				if srv_choice then
					self.connect_host, self.connect_port = srv_choice.target, srv_choice.port;
					self:debug("Best record found, will connect to %s:%d", self.connect_host or self.host, self.connect_port or 5222);
				end

				self:hook("disconnected", function ()
					if self.srv_hosts and self.srv_choice < #self.srv_hosts then
						self.srv_choice = self.srv_choice + 1;
						local srv_choice = srv_hosts[self.srv_choice];
						self.connect_host, self.connect_port = srv_choice.target, srv_choice.port;
						start_connect();
						return true;
					end
				end, 1000);

				self:hook("connected", function ()
					self.srv_hosts = nil;
				end, 1000);
			end
			start_connect();
		end, "_xmpp-client._tcp."..(self.host)..".", "SRV");
	else
		start_connect();
	end
end

function stream:reopen()
	self:reset();
	self:send(st.stanza("stream:stream", { to = self.host, ["xmlns:stream"]='http://etherx.jabber.org/streams',
		xmlns = "jabber:client", version = "1.0" }):top_tag());
end

function stream:send_iq(iq, callback)
	local id = self:new_id();
	self.tracked_iqs[id] = callback;
	iq.attr.id = id;
	self:send(iq);
end

function stream:new_id()
	self.curr_id = self.curr_id + 1;
	return tostring(self.curr_id);
end
 end)
package.preload['verse.component'] = (function (...)
					local _ENV = _ENV;
					local function module(name, ...)
						local t = package.loaded[name] or _ENV[name] or { _NAME = name };
						package.loaded[name] = t;
						for i = 1, select("#", ...) do
							(select(i, ...))(t);
						end
						_ENV = t;
						_M = t;
						return t;
					end
				local verse = require "verse";
local stream = verse.stream_mt;

local jid_split = require "util.jid".split;
local lxp = require "lxp";
local st = require "util.stanza";
local sha1 = require "util.hashes".sha1;

-- Shortcuts to save having to load util.stanza
verse.message, verse.presence, verse.iq, verse.stanza, verse.reply, verse.error_reply =
	st.message, st.presence, st.iq, st.stanza, st.reply, st.error_reply;

local new_xmpp_stream = require "util.xmppstream".new;

local xmlns_stream = "http://etherx.jabber.org/streams";
local xmlns_component = "jabber:component:accept";

local stream_callbacks = {
	stream_ns = xmlns_stream,
	stream_tag = "stream",
	 default_ns = xmlns_component };

function stream_callbacks.streamopened(stream, attr)
	stream.stream_id = attr.id;
	if not stream:event("opened", attr) then
		stream.notopen = nil;
	end
	return true;
end

function stream_callbacks.streamclosed(stream)
	return stream:event("closed");
end

function stream_callbacks.handlestanza(stream, stanza)
	if stanza.attr.xmlns == xmlns_stream then
		return stream:event("stream-"..stanza.name, stanza);
	elseif stanza.attr.xmlns or stanza.name == "handshake" then
		return stream:event("stream/"..(stanza.attr.xmlns or xmlns_component), stanza);
	end

	return stream:event("stanza", stanza);
end

function stream:reset()
	if self.stream then
		self.stream:reset();
	else
		self.stream = new_xmpp_stream(self, stream_callbacks);
	end
	self.notopen = true;
	return true;
end

function stream:connect_component(jid, pass)
	self.jid, self.password = jid, pass;
	self.username, self.host, self.resource = jid_split(jid);

	function self.data(conn, data)
		local ok, err = self.stream:feed(data);
		if ok then return; end
		stream:debug("Received invalid XML (%s) %d bytes: %s", tostring(err), #data, data:sub(1, 300):gsub("[\r\n]+", " "));
		stream:close("xml-not-well-formed");
	end

	self:hook("incoming-raw", function (data) return self.data(self.conn, data); end);

	self.curr_id = 0;

	self.tracked_iqs = {};
	self:hook("stanza", function (stanza)
		local id, type = stanza.attr.id, stanza.attr.type;
		if id and stanza.name == "iq" and (type == "result" or type == "error") and self.tracked_iqs[id] then
			self.tracked_iqs[id](stanza);
			self.tracked_iqs[id] = nil;
			return true;
		end
	end);

	self:hook("stanza", function (stanza)
		local ret;
		if stanza.attr.xmlns == nil or stanza.attr.xmlns == "jabber:client" then
			if stanza.name == "iq" and (stanza.attr.type == "get" or stanza.attr.type == "set") then
				local xmlns = stanza.tags[1] and stanza.tags[1].attr.xmlns;
				if xmlns then
					ret = self:event("iq/"..xmlns, stanza);
					if not ret then
						ret = self:event("iq", stanza);
					end
				end
				if ret == nil then
					self:send(verse.error_reply(stanza, "cancel", "service-unavailable"));
					return true;
				end
			else
				ret = self:event(stanza.name, stanza);
			end
		end
		return ret;
	end, -1);

	self:hook("opened", function (attr)
		print(self.jid, self.stream_id, attr.id);
		local token = sha1(self.stream_id..pass, true);

		self:send(st.stanza("handshake", { xmlns = xmlns_component }):text(token));
		self:hook("stream/"..xmlns_component, function (stanza)
			if stanza.name == "handshake" then
				self:event("authentication-success");
			end
		end);
	end);

	local function stream_ready()
		self:event("ready");
	end
	self:hook("authentication-success", stream_ready, -1);

	-- Initialise connection
	self:connect(self.connect_host or self.host, self.connect_port or 5347);
	self:reopen();
end

function stream:reopen()
	self:reset();
	self:send(st.stanza("stream:stream", { to = self.jid, ["xmlns:stream"]='http://etherx.jabber.org/streams',
		xmlns = xmlns_component, version = "1.0" }):top_tag());
end

function stream:close(reason)
	if not self.notopen then
		self:send("</stream:stream>");
	end
	local on_disconnect = self.conn.disconnect();
	self.conn:close();
	on_disconnect(conn, reason);
end

function stream:send_iq(iq, callback)
	local id = self:new_id();
	self.tracked_iqs[id] = callback;
	iq.attr.id = id;
	self:send(iq);
end

function stream:new_id()
	self.curr_id = self.curr_id + 1;
	return tostring(self.curr_id);
end
 end)

-- Use LuaRocks if available
pcall(require, "luarocks.require");

local socket = require"socket";

-- Load LuaSec if available
pcall(require, "ssl");

local server = require "net.server";
local events = require "util.events";
local logger = require "util.logger";

local verse = {};
verse.server = server;

local stream = {};
stream.__index = stream;
verse.stream_mt = stream;

verse.plugins = {};

function verse.init(...)
	for i=1,select("#", ...) do
		local ok, err = pcall(require, "verse."..select(i,...));
		if not ok then
			error("Verse connection module not found: verse."..select(i,...)..err);
		end
	end
	return verse;
end


local max_id = 0;

function verse.new(logger, base)
	local t = setmetatable(base or {}, stream);
	max_id = max_id + 1;
	t.id = tostring(max_id);
	t.logger = logger or verse.new_logger("stream"..t.id);
	t.events = events.new();
	t.plugins = {};
	t.verse = verse;
	return t;
end

verse.add_task = require "util.timer".add_task;

verse.logger = logger.init; -- COMPAT: Deprecated
verse.new_logger = logger.init;
verse.log = verse.logger("verse");

local function format(format, ...)
	local n, arg, maxn = 0, { ... }, select('#', ...);
	return (format:gsub("%%(.)", function (c) if n <= maxn then n = n + 1; return tostring(arg[n]); end end));
end

function verse.set_log_handler(log_handler, levels)
	levels = levels or { "debug", "info", "warn", "error" };
	logger.reset();
	if io.type(log_handler) == "file" then
		local f = log_handler;
		function log_handler(name, level, message)
			f:write(name, "\t", level, "\t", message, "\n");
		end
	end
	if log_handler then
		local function _log_handler(name, level, message, ...)
			return log_handler(name, level, format(message, ...));
		end
		for i, level in ipairs(levels) do
			logger.add_level_sink(level, _log_handler);
		end
	end
end

function verse._default_log_handler(name, level, message)
	return io.stderr:write(name, "\t", level, "\t", message, "\n");
end
verse.set_log_handler(verse._default_log_handler, { "error" });

local function error_handler(err)
	verse.log("error", "Error: %s", err);
	verse.log("error", "Traceback: %s", debug.traceback());
end

function verse.set_error_handler(new_error_handler)
	error_handler = new_error_handler;
end

function verse.loop()
	return xpcall(server.loop, error_handler);
end

function verse.step()
	return xpcall(server.step, error_handler);
end

function verse.quit()
	return server.setquitting("once");
end

function stream:listen(host, port)
	host = host or "localhost";
	port = port or 0;
	local conn, err = server.addserver(host, port, verse.new_listener(self, "server"), "*a");
	if conn then
		self:debug("Bound to %s:%s", host, port);
		self.server = conn;
	end
	return conn, err;
end

function stream:connect(connect_host, connect_port)
	connect_host = connect_host or "localhost";
	connect_port = tonumber(connect_port) or 5222;

	-- Create and initiate connection
	local conn = socket.tcp()
	conn:settimeout(0);
	conn:setoption("keepalive", true);
	local success, err = conn:connect(connect_host, connect_port);

	if not success and err ~= "timeout" then
		self:warn("connect() to %s:%d failed: %s", connect_host, connect_port, err);
		return self:event("disconnected", { reason = err }) or false, err;
	end

	local conn = server.wrapclient(conn, connect_host, connect_port, verse.new_listener(self), "*a");
	if not conn then
		self:warn("connection initialisation failed: %s", err);
		return self:event("disconnected", { reason = err }) or false, err;
	end
	self:set_conn(conn);
	return true;
end

function stream:set_conn(conn)
	self.conn = conn;
	self.send = function (stream, data)
		self:event("outgoing", data);
		data = tostring(data);
		self:event("outgoing-raw", data);
		return conn:write(data);
	end;
end

function stream:close(reason)
	if not self.conn then
		verse.log("error", "Attempt to close disconnected connection - possibly a bug");
		return;
	end
	local on_disconnect = self.conn.disconnect();
	self.conn:close();
	on_disconnect(self.conn, reason);
end

-- Logging functions
function stream:debug(...)
	return self.logger("debug", ...);
end

function stream:info(...)
	return self.logger("info", ...);
end

function stream:warn(...)
	return self.logger("warn", ...);
end

function stream:error(...)
	return self.logger("error", ...);
end

-- Event handling
function stream:event(name, ...)
	self:debug("Firing event: "..tostring(name));
	return self.events.fire_event(name, ...);
end

function stream:hook(name, ...)
	return self.events.add_handler(name, ...);
end

function stream:unhook(name, handler)
	return self.events.remove_handler(name, handler);
end

function verse.eventable(object)
        object.events = events.new();
        object.hook, object.unhook = stream.hook, stream.unhook;
        local fire_event = object.events.fire_event;
        function object:event(name, ...)
                return fire_event(name, ...);
        end
        return object;
end

function stream:add_plugin(name)
	if self.plugins[name] then return true; end
	if require("verse.plugins."..name) then
		local ok, err = verse.plugins[name](self);
		if ok ~= false then
			self:debug("Loaded %s plugin", name);
			self.plugins[name] = true;
		else
			self:warn("Failed to load %s plugin: %s", name, err);
		end
	end
	return self;
end

-- Listener factory
function verse.new_listener(stream)
	local conn_listener = {};

	function conn_listener.onconnect(conn)
		if stream.server then
			local client = verse.new();
			conn:setlistener(verse.new_listener(client));
			client:set_conn(conn);
			stream:event("connected", { client = client });
		else
			stream.connected = true;
			stream:event("connected");
		end
	end

	function conn_listener.onincoming(conn, data)
		stream:event("incoming-raw", data);
	end

	function conn_listener.ondisconnect(conn, err)
		if conn ~= stream.conn then return end
		stream.connected = false;
		stream:event("disconnected", { reason = err });
	end

	function conn_listener.ondrain(conn)
		stream:event("drained");
	end

	function conn_listener.onstatus(conn, new_status)
		stream:event("status", new_status);
	end

	return conn_listener;
end

return verse;
