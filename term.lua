loadreq.include'packages.middleclass.middleclass'
local shcopy=require'utils.table'.shcopy
local term=nil

ErrorTerm=class'ErrorTerm'
function ErrorTerm:initialize(term)
	self.term={
		getSize=term.getSize,
		setCursorPos=function(_x,_y)
			if not (type(_x)=='number' and type(_y)=='number') then
				error('Expected pair of numbers: (x,y)',2)
			end
			return term.setCursorPos(_x,_y)
		end,
		getCursorPos=term.getCursorPos,
		write=function(txt)
			if txt==nil then
				return
			elseif type(txt)=='number' then
				if txt%1==0 then
					txt=tostring(txt)..'.0'
				else
					txt=tostring(txt)
				end
			end
			if (txt=="") then
				return
			end
			return term.write(txt)
		end,
		clearLine=term.clearLine,
		scroll=function(n)
			if type(n)~='number' then error('Expected number',2) end
			return term.scroll(n)
		end,
		clear=term.clear,
		setCursorBlink=function(bool)
			if type(bool)~='boolean' then error('Expected boolean',2) end
			return term.setCursorBlink(bool)
		end,
		isColor=term.isColor,
		isColour=term.isColor,
		setTextColor=function(n)
			if type(n)~='number' then error('Expected number',2) end
			if 0==n or ( n>=1 and n<=32768) then
				return term.setTextColor(n)
			else
				error('Color out of range',2)
			end
		end,
		setTextColour=function(n)
			if type(n)~='number' then error('Expected number',2) end
			if 0==n or ( n>=1 and n<=32768) then
				return term.setTextColor(n)
			else
				error('Colour out of range',2)
			end
		end,
		setBackgroundColor=function(n)
			if type(n)~='number' then error('Expected number',2) end
			if 0==n or ( n>=1 and n<=32768) then
				return term.setBackgroundColor(n)
			else
				error('Color out of range',2)
			end
		end,
		setBackgroundColour=function(n)
			if type(n)~='number' then error('Expected number',2) end
			if 0==n or ( n>=1 and n<=32768) then
				return term.setBackgroundColor(n)
			else
				error('Colour out of range',2)
			end
		end,
	}
end

GridTerm=class'GridTerm'
function GridTerm:initialize(X,Y,isColor)
	local matrix={}
	for i=1,Y do
		local t={}
		matrix[i]=t
		for j=1,X do
			t[j]={' ',colors.white,colors.black}
		end
	end
	self.matrix=matrix
	
	local term
	do
		local textColor=colors.white
		local backgroundColor=colors.black
		local blink=true
		local x,y=1,1
		term={
			getSize=function() return X,Y end,
			setCursorPos=function(_x,_y) x,y=_x,_y end,
			getCursorPos=function() return x,y end,
			
			write=function(txt)
				if (y < 1) or (y > Y) or (x > X) then
				   x = x + #txt
				   return
				end
				if x < 1 then
					txt=txt:sub(2-x)
					x=1
				end
				
				local line = matrix[y]
				
				local n = #txt
				for i=1,math.min(X-x+1,n,X) do
					local char=txt:sub(i,i)
					if not ((char==nil) or (char=="")) then
						local t=line[i+x-1]
						t[1]=char
						t[2]=textColor==0 and (t[2] or colors.white) or textColor
						t[3]=textColor==0 and (t[3] or colors.black) or backgroundColor
					end
				end
				x = x + n
			end,
			
			
			clearLine=function()
				line=matrix[y]
				if line then
					for i=1,X do
						local t=line[i]
						t[1]=' '
						t[2]=textColor==0 and (t[2] or colors.white) or textColor
						t[3]=textColor==0 and (t[3] or colors.black) or backgroundColor
					end
				end
			end,
			scroll=function(n)
				if n>0 then
					for i=1,n do
						local new_line={}
						for j=1,X do
							local t={}
							new_line[j]=t
							t[1]=' '
							t[2]=textColor==0 and (t[2] or colors.white) or textColor
							t[3]=textColor==0 and (t[3] or colors.black) or backgroundColor
						end
						table.insert(matrix,new_line)
						table.remove(matrix,1)
					end
				else
					n=-n
					for i=1,n do
						local new_line={}
						for j=1,X do
							local t={}
							new_line[j]=t
							t[1]=' '
							t[2]=textColor==0 and (t[2] or colors.white) or textColor
							t[3]=textColor==0 and (t[3] or colors.black) or backgroundColor
						end
						table.insert(matrix,new_line,1)
						table.remove(matrix)
					end
				end
			end,
			
			clear=function()
				for i=1,Y do
					local line = matrix[i]
					for j=1,X do
						local t=line[j]
						t[1]=' '
						t[2]=textColor==0 and (t[2] or colors.white) or textColor
						t[3]=textColor==0 and (t[3] or colors.black) or backgroundColor
					end
				end
			end,
			
			setCursorBlink=function(bool) blink=bool end,
			
			isColor=function() return isColor end,
			setTextColor=function(n) textColor=n end,
			setBackgroundColor=function(n) backgroundColor=n end,
		}
		do
			local native = term
			local redirectTarget = native
			local tRedirectStack = {}
			
			local function wrap( _sFunction )
				return function( ... )
					return redirectTarget[ _sFunction ]( ... )
				end
			end
			
			term = {}
			for k,v in pairs( native ) do
				if type( k ) == "string" and type( v ) == "function" then
					if term[k] == nil then
						term[k] = wrap( k )
					end
				end
			end
			
			term.redirect = function( _object )
				if _object == nil or type( _object ) ~= "table" then
					error( "Invalid redirect object" )
				end
				for k,v in pairs( native ) do
					if type( k ) == "string" and type( v ) == "function" then
						if type( _object[k] ) ~= "function" then
							_object[k] = function() 
								term.restore()
								error( "Redirect object is missing method "..k..". Restoring.")
							end
						end
					end
				end

				tRedirectStack[#tRedirectStack + 1] = redirectTarget
				redirectTarget = _object
			end
			term.restore = function()
				if #tRedirectStack > 0 then
					redirectTarget = tRedirectStack[#tRedirectStack] 
					tRedirectStack[#tRedirectStack] = nil
				end
			end
		end
		setmetatable(term,{__index={
		getCursorBlink=function() return blink end,
		getTextColor=function() return textColor end,
		getBackgroundColor=function() return backgroundColor end,
		}
		})
	end
	self.term=term
end

function GridTerm:draw(term)
	local matrix=self.matrix
	local X,Y = self.term.getSize()
	for i=1,Y do
		term.setCursorPos(1,i)
		local line=matrix[i]
		local text={line[1][1]}
		local cText=line[1][2]
		local cBack=line[1][3]
		for j=2,X do
			local t=line[j]
			if cText~=t[2] or cBack~=t[3] then
				term.setTextColor(cText)
				term.setBackgroundColor(cBack)
				term.write(table.concat(text))
				text={t[1]}
				cText=t[2]
				cBack=t[3]
			else
				table.insert(text,t[1])
			end
		end
		term.setTextColor(cText)
		term.setBackgroundColor(cBack)
		term.write(table.concat(text))
	end
end

function resetTerm(term)
	term.setTextColor(colors.white)
	term.setBackgroundColor(colors.black)
	term.setCursorPos(1,1)
	term.clear()
end

function copyState(org,dest)
	dest.setCursorPos(org.getCursorPos())
	dest.setCursorBlink(org.getCursorBlink())
	dest.setTextColor(org.getTextColor())
	dest.setBackgroundColor(org.getBackgroundColor())
end

TransformTerm=class'TransformTerm'
function TransformTerm:initialize(term,X,Y,dx,dy)
	self.dx=dx or 0
	self.dy=dy or 0
	self.X,self.Y=X,Y
	local space_line=string.rep(' ',self.X)
	self.term={
			getSize=function() return self.X,self.Y end,
			setCursorPos=function(x,y)
				return term.setCursorPos(x+self.dx,y+self.dy)
			end,
			getCursorPos=function()
				local x,y=term.getCursorPos()
				return x-self.dx,y-self.dy
			end,
			write=function(txt)
				term.write(txt:sub(1,self.X))
			end,
			clearLine=function()
				local _x,_y=term.getCursorPos()
				term.setCursorPos(self.dx+1,_y)
				term.write(space_line)
				term.setCursorPos(_x,_y)
			end,
			clear=function()
				local _x,_y=term.getCursorPos()
				for i=1,Y do
					self.term.setCursorPos(1,i)
					term.write(space_line)
				end
				term.setCursorPos(_x,_y)
			end,
			scroll=function()
				error('scroll non-defined for TransformTerm',2)
			end,
			setCursorBlink=term.setCursorBlink,
			isColor=term.isColor,
			setTextColor=term.setTextColor,
			setBackgroundColor=term.setBackgroundColor,
		}
end



local term_actions={
'write',
'scroll',
'clear',
'clearLine',
'write',
'setCursorPos',
'setTextColor',
'setBackgroundColor',
'setCursorBlink',
}
local term_passive={
'getCursorPos',
'isColor',
}



WindowTerm=class'WindowTerm'
do

function WindowTerm:initialize(term,X,Y,dx,dy)
	local saveTerm=GridTerm(X,Y,term.isColor())
	term = TransformTerm(term,X,Y,dx,dy).term
	
	self.dest=term
	local term=shcopy(self.dest)
	term.scroll=function(n)
		saveTerm:draw(self.dest)
		copyState(saveTerm.term,self.dest)
	end
	local s_term=saveTerm.term
	self.active=false
	self.term={}
	for _,v in pairs(term_actions) do
		local f=term[v]
		local s_f=s_term[v]
		self.term[v]=function(...)
			s_f(...)
			if self.active then
				f(...)
			end
		end
	end
	for _,v in pairs(term_passive) do
		self.term[v]=s_term[v]
	end
	self.saveTerm=saveTerm
	
	self.term = ErrorTerm(self.term).term
end

function WindowTerm:draw()
	return self.saveTerm:draw(self.dest)
end

local function activate(self)
	self.saveTerm:draw(self.dest)
	copyState(self.saveTerm.term,self.dest)
	self.active=true
end

function WindowTerm:setActive(bool)
	if bool~=self.active then
		if bool then
			self:activate()
		else
			self.active=false
		end
	end
end

end



-- Window=class('Window',WindowTerm)
-- function Window:initialize(term,X,Y,dx,dy)
	-- WindowTerm.initialize(self,TransformTerm(term,X,Y,dx,dy).term,GridTerm(X,Y,term.isColor()))
	-- self.term = ErrorTerm(self.term).term
-- end




local PipeTerm={}