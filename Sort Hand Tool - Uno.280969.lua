-- Sort Hand Tool
-- This tool lets the calling player sort the cards in their hand by triggering via scripting hotkey.
-- This tool can be customized for a specific player by setting the Description to a valid player color (White, Brown, Red, Orange, Yellow, Green, Teal, Blue, Purple, Pink, Grey, Black).



--  ======================================================================
--						Configuration
--  ======================================================================



-- The scripting hotkey (i.e. Numpad #) this tools is binding to.
scriptHotKey = 1



-- This is the way suits (i.e. values in the cards' Description field) are grouped
-- 0:  Ignore suits
-- 1:  All suits are together
-- 2:  All card numbers are together
groupSuitMode = 1



-- This is the reference order of card values and suits (as you want them to appear from left to right).  Values are labeled in the card Name, suits are labeled in the card Description.
-- NOTE:  Several example sort orders are shown below.  Only enable ONE set (whether from the included examples, or a custom one of your own).
-- If you have no suit names (i.e. Description field), just leave this as-is and set groupSuitMode = 0


-- Left to Right Order
-- refCardOrder = {"Ace", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine", "Ten", "Jack", "Queen", "King", "Joker", }
-- refSuitOrder = {"Heart", "Club", "Diamond", "Spade", "BW", "Color", }

-- New-Deck Order
-- refCardOrder = {"King", "Queen", "Jack", "Ten", "Nine", "Eight", "Seven", "Six", "Five", "Four", "Three", "Two", "Ace", "Joker", }
-- refSuitOrder = {"Heart", "Club", "Diamond", "Spade", "BW", "Color", }

-- Ding Pai Order
-- refCardOrder = {"Joker", "Four", "Three", "Two", "Ace", "King", "Queen", "Jack", "Ten", "Nine", "Eight", "Seven", "Six", "Five", }
-- refSuitOrder = {"Color", "BW", "Spade", "Heart", "Club", "Diamond", }

-- Ding Pai Order - Reversed
-- refCardOrder = {"Five", "Six", "Seven", "Eight", "Nine", "Ten", "Jack", "Queen", "King", "Ace", "Two", "Three", "Four", "Joker", }
-- refSuitOrder = {"Diamond", "Club", "Heart", "Spade", "BW", "Color", }

-- Uno Order (covers some of the specialty versions)
refCardOrder = {"0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "skip", "reverse", "wild", "+2", "+4", "+4 reverse" }
refSuitOrder = {"WILD", "BLUE", "GREEN", "RED", "YELLOW", }





--  ======================================================================
--						End Configuration
--  ======================================================================



-- Reverse Index of refCardOrder
-- Used as a high performance method (i.e. no iteration) to find the index of a given value, such as:
-- return refCardOrderIndex["Seven"]
local refCardOrderIndex={}
for k,v in pairs(refCardOrder) do
	refCardOrderIndex[v]=k
end


-- Reverse Index of refSuitOrder
-- Used as a high performance method (i.e. no iteration) to find the index of a given value, such as:
-- return refSuitOrderIndex["Diamond"]
local refSuitOrderIndex={}
for k,v in pairs(refSuitOrder) do
	refSuitOrderIndex[v]=k
end



-- Table of all valid player colors.
playerColorList = {'White', 'Brown', 'Red', 'Orange', 'Yellow', 'Green', 'Teal', 'Blue', 'Purple', 'Pink', 'Grey', 'Black', }



function onLoad()

	local button = {}
	button.label = "" button.height = 600 button.width = 600 button.font_size = 500 button.position = {0, 0.15, 0} button.rotation = {0, 0, 0} button.click_function = 'sortHand' button.function_owner = self self.createButton(button)
	button.label = "" button.height = 600 button.width = 600 button.font_size = 500 button.position = {0, 0.10, 0} button.rotation = {0, 0, 180} button.click_function = 'sortHand' button.function_owner = self self.createButton(button)
	self.interactable = true
end




-- Support scripting hotkey NumPad 1.
function onScriptingButtonUp(index, player_color)

	
	-- Check the tool's description to see if someone has claimed it for a specific player.
	toolDescription = self.getDescription()
	
	-- If the tool's description contains a valid player color that does not match the calling player, do nothing.  Otherwise, allow the sort to continue.
	if tableContains(playerColorList, toolDescription) == true and toolDescription != player_color then
		
		return
		
	end
	
	
	
	
	-- If we're flipped non-hotkey side up, then print a message if someone tries to activate it.
	if index == scriptHotKey and (self.getRotation().z > 340 or self.getRotation().z < 20) then 
		
		-- printToColor("[00ff00]Sort Hand Tool[-]: Flip the tool to enable hotkeys.", player_color, {1,1,1})
		-- broadcastToColor("[00ff00]Sort Hand Tool[-]: Flip the tool to enable hotkeys.", player_color, {1,1,1})
	
	
	-- If we're flipped hotkey side up AND the correct scripting hotkey was pressed, then sort.
	else 
		
		if index == scriptHotKey then 
		
			sortHand(self, player_color)
		
		end 
	
	end

end


-- Sort the calling player's hand.
function sortHand(obj, player_color)
	
	-- Table to store the sortable list of cards present in the hand.
	local cards = {}
	
	-- Table to store the list of card positions in the hand.
	local handPos = {}
	
	-- Grab the list of cards in the hand.  We'll use this to populate our tables.
	handObjects = Player[player_color].getHandObjects()
	
	
	-- Flag to indicate whether the error handling routine found an improperly named card.
	ErrorMode = 0


	-- Populate both tables.
	for i, j in pairs(handObjects) do
		
		local cardNumber = j.getName()
		local cardSuit = j.getDescription()
		
		
		-- Error Handling
		if cardNumber == '' or (groupSuitMode != 0 and cardSuit == '') then
			
			broadcastToColor("[00ff00]Sort Hand Tool[-]: Card missing name or needed description.", player_color, {1,1,1})
			log(j, 'Card with missing name or needed description:')
			ErrorMode = 1
			return
			
		end

		
		table.insert(cards, {j, j.getName()})
		table.insert(handPos, j.getPosition())
	
	end
	
	
	if ErrorMode == 1 then
		return
	end
	
	
	-- Sort the list of cards.
	table.sort(cards, sortLogic)

	-- Take the sorted list of cards and apply the list of card positions in order to physically rearrange them.
	for i, j in ipairs(cards) do
	
		j[1].setPosition(handPos[i])
	
	end
		
	
end


-- Comparison function used by table.sort()
-- The parameters supplied by table.sort() are tables, where parameter[1] is the object reference, and parameter[2] is the object Name.
function sortLogic(card1, card2)
	
	-- Grab the relevant information for both cards.
	card1Number = card1[1].getName()
	card1NumberIndex = refCardOrderIndex[card1Number]
	card1Suit = card1[1].getDescription()
	card1SuitIndex = refSuitOrderIndex[card1Suit]
	
	card2Number = card2[1].getName()
	card2NumberIndex = refCardOrderIndex[card2Number]
	card2Suit = card2[1].getDescription()
	card2SuitIndex = refSuitOrderIndex[card2Suit]


	-- log(card1Number, 'card1Number:')
	-- log(card1NumberIndex, 'card1NumberIndex:')
	-- log(card1Suit, 'card1Suit:')
	-- log(card1SuitIndex, 'card1SuitIndex:')


	-- 0: Ignore all suits.
	if groupSuitMode == 0 then
		
		return card1NumberIndex < card2NumberIndex
		
	end




	-- 1: All suits are together
	if groupSuitMode == 1 then
		
		if card1Suit == card2Suit then
			
			return card1NumberIndex < card2NumberIndex
			
		else
			
			return card1SuitIndex < card2SuitIndex
			
		end
		
	end
	
	
	
	-- 2: All card numbers are together
	if groupSuitMode == 2 then
		
		if card1Number == card2Number then
			
			return card1SuitIndex < card2SuitIndex
			
		else
			
			return card1NumberIndex < card2NumberIndex
			
		end
		
	end
	
	
	
end


-- Function to determine whether a specified value/object exists in a table.
function tableContains(tableSpecified, element)
	
	for _, value in pairs(tableSpecified) do
	
		if value == element then
			return true
		end
		
	end
	
	return false
	
end