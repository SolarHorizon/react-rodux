local React = require(script.Parent.Parent.React)
local Rodux = require(script.Parent.Parent.Rodux)
local Context = require(script.Parent.Context)

local e = React.createElement

type Props = {
	context: React.Context<unknown>?,
	store: Rodux.Store<unknown>,
	children: React.ReactNode,
}

--[=[
	@within ReactRodux
	@interface ProviderProps
	.store: Store -- Your Rodux store
	.context: Context? -- Optional custom context
]=]

--[=[
	@within ReactRodux
	@function Provider
	@param props ProviderProps

	The Provider component makes your Rodux store available to all of its 
	children. You should mount this at the top level of your React tree if so 
	your whole app is able to use React Rodux.

	```lua
	local function App(props)
		return e(ReactRodux.Provider, {
			store = store,
		}, {
			-- your app goes here
		})
	end
	```
]=]
local Provider: React.FC<Props> = function(props)
	local context = props.context or Context

	return e(context.Provider, {
		value = props.store,
	}, props.children)
end

return Provider
