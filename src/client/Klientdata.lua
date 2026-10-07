-- Det klienten vet om seg selv: siste «Status» fra serveren (penger, oppgraderinger, samlebok, base ...).
-- Moduler lytter med Klientdata.lytt(funksjon), som kalles hver gang statusen endrer seg.
local Klientdata = {}

Klientdata.status = { penger = 0, inntekt = 0, oppgr = {}, index = {}, sokler = 0, tyverier = 0 }
local lyttere = {}

function Klientdata.lytt(f)
	table.insert(lyttere, f)
	task.spawn(f, Klientdata.status)
end

function Klientdata.sett(st)
	if type(st) ~= "table" then
		return
	end
	local forrige = Klientdata.status
	Klientdata.status = st
	for _, f in lyttere do
		task.spawn(f, st, forrige)
	end
end

return Klientdata
