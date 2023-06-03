local Context = require(script.Parent.Context)
local createSelectorHook = require(script.Parent.createSelectorHook)

--[=[
	@within ReactRodux
	@function createSelectorHook
	@param context ReactContext<Store>
	@return useStore

	This is the primary way to get data from a Rodux store with React Rodux. 
	Multiple useSelector hooks can be used in the same component.

	By default, useSelector will directly compare the previous value returned 
	by selector to the most recent one. When the old and new values are not
	equal, the component will be re-rendered with the updated state. You can 
	optionally pass a function to equalityFn for finer control over this.

	```lua
	local function ExampleLabel(props)
		local money = ReactRodux.useSelector(function(state)
			return state.money
		end)

		return e(MoneyLabel, {
			amount = money,
		})
	end
	```
]=]
return createSelectorHook(Context)
