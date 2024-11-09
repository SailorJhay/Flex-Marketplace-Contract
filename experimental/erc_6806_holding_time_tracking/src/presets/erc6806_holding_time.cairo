use starknet::ContractAddress;

#[starknet::interface]
pub trait IERC6806HoldingTime<TState> {
    fn mint(ref self: TState, to: ContractAddress, token_id: u256);
}

#[starknet::interface]
pub trait IERC6806HoldingTimeMixin<TState> {
    // IERC6806HoldingTime
    fn holding_time(self: @TState, token_id: u256) -> (ContractAddress, u64);
    fn set_exempt_holder(ref self: TState, holder: ContractAddress, exempt: bool);
    
    // IERC721
    fn balance_of(self: @TState, account: ContractAddress) -> u256;
    fn owner_of(self: @TState, token_id: u256) -> ContractAddress;
    fn safe_transfer_from(
        ref self: TState,
        from: ContractAddress,
        to: ContractAddress,
        token_id: u256,
        data: Span<felt252>
    );
    fn transfer_from(ref self: TState, from: ContractAddress, to: ContractAddress, token_id: u256);
    fn approve(ref self: TState, to: ContractAddress, token_id: u256);
    fn set_approval_for_all(ref self: TState, operator: ContractAddress, approved: bool);
    fn get_approved(self: @TState, token_id: u256) -> ContractAddress;
    fn is_approved_for_all(
        self: @TState, owner: ContractAddress, operator: ContractAddress
    ) -> bool;
    
    // Ownable
    fn owner(self: @TState) -> ContractAddress;
    fn transfer_ownership(ref self: TState, new_owner: ContractAddress);
    fn renounce_ownership(ref self: TState);
    
    // ISRC5
    fn supports_interface(self: @TState, interface_id: felt252) -> bool;
}

#[starknet::contract]
pub mod ERC6806HoldingTime {
    use starknet::{ContractAddress, get_caller_address};
    use openzeppelin_introspection::src5::SRC5Component;
    use openzeppelin_access::ownable::OwnableComponent;
    use openzeppelin_token::erc721::{ERC721Component, ERC721HooksEmptyImpl};
    use erc_6806_holding_time_tracking::erc6806::erc6806::ERC6806Component;

    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    component!(path: ERC721Component, storage: erc721, event: ERC721Event);
    component!(path: ERC6806Component, storage: erc6806, event: ERC6806Event);

    // ERC6806
    #[abi(embed_v0)]
    impl ERC6806Impl = ERC6806Component::ERC6806Impl<ContractState>;
    impl ERC6806InternalImpl = ERC6806Component::InternalImpl<ContractState>;

    // Ownable
    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    // ERC721
    #[abi(embed_v0)]
    impl ERC721MixinImpl = ERC721Component::ERC721MixinImpl<ContractState>;
    impl ERC721InternalImpl = ERC721Component::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        erc721: ERC721Component::Storage,
        #[substorage(v0)]
        erc6806: ERC6806Component::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        SRC5Event: SRC5Component::Event,
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        ERC721Event: ERC721Component::Event,
        #[flat]
        ERC6806Event: ERC6806Component::Event,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState, 
        name: ByteArray, 
        symbol: ByteArray, 
        base_uri: ByteArray
    ) {
        self.ownable.initializer(get_caller_address());
        self.erc721.initializer(name, symbol, base_uri);
        self.erc6806.initializer();
    }

    #[abi(embed_v0)]
    impl ERC6806HoldingTimeImpl of super::IERC6806HoldingTime<ContractState> {
        fn mint(ref self: ContractState, to: ContractAddress, token_id: u256) {
            self.ownable.assert_only_owner();
            self.erc721.mint(to, token_id);
        }
    }
}