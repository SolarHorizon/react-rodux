local Context = require(script.Parent.Context)
local createDispatchHook = require(script.Parent.createDispatchHook)

--[=[
	@within ReactRodux
	@function createDispatchHook
	@param context ReactContext<Store>
	@return useStore

	Returns the dispatch function of Rodux store that was passed into the 
	Provider.

	```lua
	local function ExampleButton(props)
		local dispatch = ReactRodux.useDispatch()

		return e(Button, {
			onClick = function()
				dispatch({
					type = "moneyAdded",
					amount = 100,
				})
			end,
		})
	end
	```
]=]
return createDispatchHook(Context)
