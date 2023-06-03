local Provider = require(script.Provider)
local createDispatchHook = require(script.createDispatchHook)
local createSelectorHook = require(script.createSelectorHook)
local createStoreHook = require(script.createStoreHook)
local shallowEqual = require(script.shallowEqual)
local useDispatch = require(script.useDispatch)
local useSelector = require(script.useSelector)
local useStore = require(script.useStore)

--[=[
	@class ReactRodux
]=]

return {
	Provider = Provider,
	createDispatchHook = createDispatchHook,
	createSelectorHook = createSelectorHook,
	createStoreHook = createStoreHook,
	shallowEqual = shallowEqual,
	useDispatch = useDispatch,
	useSelector = useSelector,
	useStore = useStore,
}
