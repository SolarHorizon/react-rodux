local React = require(script.Parent.Parent.React)
local Rodux = require(script.Parent.Parent.Rodux)

export type StoreContext<State> = React.Context<Rodux.Store<State>>

local Context: StoreContext<unknown> = React.createContext({} :: any)

return Context
