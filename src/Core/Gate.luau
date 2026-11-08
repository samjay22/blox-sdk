--!strict
--!native
--!optimize 2
local Gate = {}
export type Ticket = {
	granted: boolean,
	queued: boolean,
	critical: boolean,
	low: boolean,
	previous: Ticket?,
	next: Ticket?,
}
export type Lane = { head: Ticket?, tail: Ticket? }
export type State = {
	active: number,
	queued: number,
	maximum: number,
	capacity: number,
	critical: Lane,
	bulk: Lane,
	low: Lane,
	streak: number,
}
--- Create three O(1) intrusive FIFO lanes; cancelled entries are immediately unlinked.
function Gate.new(maximum: number, capacity: number): State
	return {
		active = 0,
		queued = 0,
		maximum = maximum,
		capacity = capacity,
		critical = {},
		bulk = {},
		low = {},
		streak = 0,
	}
end
--- Enqueue or acquire a physical HTTP slot; nil means backpressure.
function Gate.enter(self: State, critical: boolean, low: boolean?): Ticket?
	local ticket: Ticket = { granted = false, queued = false, critical = critical, low = low == true }
	if self.active < self.maximum and self.queued == 0 then
		self.active += 1
		ticket.granted = true
		return ticket
	end
	if self.queued >= self.capacity then
		return nil
	end
	local lane = if critical then self.critical elseif low then self.low else self.bulk
	ticket.queued = true
	ticket.previous = lane.tail
	if lane.tail then
		lane.tail.next = ticket
	else
		lane.head = ticket
	end
	lane.tail = ticket
	self.queued += 1
	return ticket
end
--- Remove a waiting ticket in O(1), including cancelled interior entries.
function Gate.remove(self: State, ticket: Ticket)
	if not ticket.queued then
		return
	end
	local lane = if ticket.critical then self.critical elseif ticket.low then self.low else self.bulk
	if ticket.previous then
		ticket.previous.next = ticket.next
	else
		lane.head = ticket.next
	end
	if ticket.next then
		ticket.next.previous = ticket.previous
	else
		lane.tail = ticket.previous
	end
	ticket.next = nil
	ticket.previous = nil
	ticket.queued = false
	self.queued -= 1
end
--- Release only on physical completion; reserve fairness after three critical dispatches.
function Gate.release(self: State)
	self.active -= 1
	local ticket = if self.streak < 3
		then self.critical.head or self.bulk.head or self.low.head
		else self.bulk.head or self.critical.head or self.low.head
	if ticket then
		Gate.remove(self, ticket)
		ticket.granted = true
		self.active += 1
		self.streak = if ticket.critical then self.streak + 1 else 0
	end
end
return table.freeze(Gate)
