#[starknet::component]
pub mod ERC6806Component {
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp};
    use starknet::storage::{
        Map, StoragePathEntry, StoragePointerReadAccess, StoragePointerWriteAccess
    };
    use openzeppelin_introspection::src5::SRC5Component::InternalTrait as SRC5InternalTrait;
    use openzeppelin_introspection::src5::SRC5Component;
    use openzeppelin_token::erc721::ERC721Component::InternalImpl as ERC721InternalImpl;
    use openzeppelin_token::erc721::ERC721Component::ERC721Impl;
    use openzeppelin_token::erc721::ERC721Component;
    use openzeppelin_access::ownable::OwnableComponent;
    use erc_6806_holding_time_tracking::erc6806::interface::{IERC6806, IERC6806_ID};

    #[storage]
    pub struct Storage {
        hold_start_time: Map<u256, u64>,
        exempt_holder: Map<ContractAddress, bool>,
    }

    #[event]
    #[derive(Drop, PartialEq, starknet::Event)]
    pub enum Event {
        ExemptHolder: ExemptHolder,
    }

    /// Emitted when `holder` is exempted from holding time.
    #[derive(Drop, PartialEq, starknet::Event)]
    pub struct ExemptHolder {
        #[key]
        pub holder: ContractAddress,
        pub exempted: bool,
    }

    //
    // External
    //

    #[embeddable_as(ERC6806Impl)]
    impl ERC6806<
        TContractState,
        +HasComponent<TContractState>,
        // impl Ownable: OwnableComponent::HasComponent<TContractState>,
        impl ERC721: ERC721Component::HasComponent<TContractState>,
        +ERC721Component::ERC721HooksTrait<TContractState>,
        impl SRC5: SRC5Component::HasComponent<TContractState>,
        +Drop<TContractState>,
    > of IERC6806<ComponentState<TContractState>> {
        fn holding_time(
            self: @ComponentState<TContractState>, token_id: u256
        ) -> (ContractAddress, u64) {
            let erc721_component = get_dep_component!(self, ERC721);
            let owner = erc721_component.owner_of(token_id);

            let hold_start_time = self.hold_start_time.entry(token_id).read();
            let timestamp = get_block_timestamp();

            let holding_time = if self.exempt_holder.entry(owner).read() {
                0
            } else {
                timestamp - hold_start_time
            };

            (owner, holding_time)
        }

        fn set_exempt_holder(
            ref self: ComponentState<TContractState>, holder: ContractAddress, exempt: bool
        ) {
            // let caller = get_caller_address();
            
            // let ownable_component = get_dep_component!(@self, Ownable);
            // ownable_component.assert_only_owner();

            self.exempt_holder.entry(holder).write(exempt);

            self.emit(ExemptHolder { holder, exempted: exempt });
        }
    }

    //
    // Internal
    //

    #[generate_trait]
    pub impl InternalImpl<
        TContractState,
        +HasComponent<TContractState>,
        impl ERC721: ERC721Component::HasComponent<TContractState>,
        +ERC721Component::ERC721HooksTrait<TContractState>,
        impl SRC5: SRC5Component::HasComponent<TContractState>,
        +Drop<TContractState>,
    > of InternalTrait<TContractState> {
        fn initializer(ref self: ComponentState<TContractState>) {
            let mut src5_component = get_dep_component_mut!(ref self, SRC5);
            src5_component.register_interface(IERC6806_ID);
        }

        fn after_update(
            ref self: ComponentState<TContractState>,
            to: ContractAddress,
            token_id: u256,
            auth: ContractAddress
        ) {
            // Skip if either receiver is exempt
            if self.exempt_holder.entry(to).read() {
                return ();
            }
            
            let timestamp = get_block_timestamp();
            self.hold_start_time.entry(token_id).write(timestamp);
        }
    }
}
