<template>
  <div class="body main-font">

    <b-tabs justified>
      <b-tab @click="clearData()">
        <template #title>
          Browse NFTs
          <hint class="hint" text="NFT stands for Non Fungible Token.<br>Weapons and Characters are NFTs of the ERC721 standard" />
        </template>

        <div class="row mt-3">
          <div class="col">

            <div class="row button-row">
              <div class="col">
                <b-button
                  variant="primary"
                  @click="searchAllListingsByType('character')"  class="gtag-link-others" tagname="browse_characters">Browse Characters</b-button>
              </div>

              <div class="col">
                <b-button
                  variant="primary"
                  @click="searchAllListingsByType('weapon')"  class="gtag-link-others" tagname="browse_weapons">Browse Weapons</b-button>
              </div>

              <div class="col">
                <b-button
                  variant="primary"
                  v-if="buyableNftSelected"
                  @click="purchaseNft()"  class="gtag-link-others" tagname="confirm_purchase">Purchase</b-button>
              </div>

              <div class="col"></div>
            </div>

            <div class="search-results">
              <weapon-grid
                v-if="activeType === 'weapon'"
                :showGivenWeaponIds="true"
                :weaponIds="allSearchResults"
                :showLimit="60"
                :showReforgedToggle="false"
                :canFavorite="false"
                v-model="selectedNftId">

                <template #above="{ weapon: { id } }">
                  <span class="d-block text-center" v-if="nftPricesById[id]">
                    <strong>Price</strong>: {{ convertWeiToSkill(nftPricesById[id]) | maxDecimals(2) }} SKILL
                  </span>
                  <span class="d-block text-center" v-else>Loading price...</span>
                </template>

              </weapon-grid>

              <character-list
                v-if="activeType === 'character'"
                :showFilters="true"
                :showGivenCharacterIds="true"
                :characterIds="allSearchResults"
                :showLimit="40"
                v-model="selectedNftId">

                <template #above="{ character: { id } }">
                  <span class="d-block text-center" v-if="nftPricesById[id]">
                    <strong>Price</strong>: {{ convertWeiToSkill(nftPricesById[id]) | maxDecimals(2) }} SKILL
                  </span>
                  <span class="d-block text-center" v-else>Loading price...</span>
                </template>

              </character-list>
            </div>

          </div>
        </div>

        <div class="row">
          <div class="col">
            <div class="outcome" v-if="waitingMarketOutcome">
              <i class="fas fa-spinner fa-spin"></i>
              Loading...
            </div>

            <div class="outcome" v-if="marketOutcome !== null">{{ marketOutcome }}</div>
          </div>
        </div>
      </b-tab>

      <b-tab @click="clearData()">
        <template #title>
          Search NFTs
          <hint class="hint" text="NFT stands for Non Fungible Token.<br>Weapons and Characters are NFTs of the ERC721 standard" />
        </template>

        <div class="row mt-3">
          <div class="col">
            <div class="row">
              <div class="col"></div>
              <div class="col">
                <input class="form-control search" type="text" v-model.trim="search" placeholder="Seller Address, NFT ID" />
              </div>
              <div class="col"></div>
            </div>

            <div class="row buttons-row mt-3">
              <div class="col">
                <b-button
                  variant="primary"
                  :disabled="!search"
                  @click="searchListingsByNftId('character')"  class="gtag-link-others" tagname="search_character_id">Search Character ID</b-button>
              </div>

              <div class="col">
                <b-button
                  variant="primary"
                  :disabled="!search"
                  @click="searchListingsByNftId('weapon')"  class="gtag-link-others" tagname="search_weapon_id">Search Weapon ID</b-button>
              </div>

              <div class="col">
                <b-button
                  variant="primary"
                  :disabled="!search"
                  @click="searchListingsBySeller('weapon')"  class="gtag-link-others" tagname="weapons_seller">Weapons by Seller</b-button>
              </div>

              <div class="col">
                <b-button
                  variant="primary"
                  :disabled="!search"
                  @click="searchListingsBySeller('character')"  class="gtag-link-others" tagname="characters_seller">Characters by Seller</b-button>
              </div>

              <div class="col">
                <b-button
                  variant="primary"
                  @click="searchOwnListings('weapon')"  class="gtag-link-others" tagname="search_own_weapons">Search My Weapons</b-button>
              </div>

              <div class="col">
                <b-button
                  variant="primary"
                  @click="searchOwnListings('character')"  class="gtag-link-others" tagname="search_own_characters">Search My Characters</b-button>
              </div>

              <div class="col">
                <b-button
                  variant="primary"
                  v-if="buyableNftSelected"
                  @click="purchaseNft()"  class="gtag-link-others" tagname="confirm_purchase">Purchase</b-button>
              </div>

              <div class="col">
                <b-button
                  variant="primary"
                  v-if="ownListedNftSelected"
                  @click="updateNftListingPrice()"  class="gtag-link-others" tagname="change_price">Change Price</b-button>
              </div>

              <div class="col">
                <b-button
                  variant="primary"
                  v-if="ownListedNftSelected"
                  @click="updateNftListingTargetBuyer()"  class="gtag-link-others" tagname="change_price">Change Target Buyer</b-button>
              </div>

              <div class="col">
                <b-button
                  variant="primary"
                  v-if="ownListedNftSelected"
                  v-tooltip="'Cancelled sales cannot be re-listed for 24 hours!'"
                  @click="cancelNftListing()"  class="gtag-link-others" tagname="cancel_listing">Cancel Listing</b-button>
              </div>
            </div>

            <div class="search-results">
              <weapon-grid
                v-if="activeType === 'weapon'"
                :showGivenWeaponIds="true"
                :showReforgedToggle="false"
                :canFavorite="false"
                :weaponIds="searchResults"
                v-model="selectedNftId">

                <template #above="{ weapon: { id } }">
                  <span class="d-block text-center" v-if="nftPricesById[id]">
                    <strong>Price</strong>: {{ convertWeiToSkill(nftPricesById[id]) | maxDecimals(2) }} SKILL
                  </span>
                  <span class="d-block text-center" v-else>Loading price...</span>
                </template>

              </weapon-grid>

              <character-list
                :showFilters="true"
                v-if="activeType === 'character'"
                :showGivenCharacterIds="true"
                :characterIds="searchResults"
                v-model="selectedNftId">

                <template #above="{ character: { id } }">
                  <span class="d-block text-center" v-if="nftPricesById[id]">
                    <strong>Price</strong>: {{ convertWeiToSkill(nftPricesById[id]) | maxDecimals(2) }} SKILL
                  </span>
                  <span class="d-block text-center" v-else>Loading price...</span>
                </template>

              </character-list>
            </div>
          </div>
        </div>

        <div class="row">
          <div class="col">
            <div class="outcome" v-if="waitingMarketOutcome">
              <i class="fas fa-spinner fa-spin"></i>
              Loading...
            </div>

            <div class="outcome" v-if="marketOutcome !== null">{{ marketOutcome }}</div>
          </div>
        </div>
      </b-tab>

      <b-tab @click="clearData();loadMarketTaxes()">
        <template #title>
          List NFTs
          <hint class="hint" text="When you list an NFT for sale, it is transferred to the<br>market until someone buys it or you cancel the sale" />
        </template>

        <div class="row mt-3">
          <div class="col">
            <div class="row button-row">
              <div class="col">
                <b-button
                  variant="primary"
                  @click="activeType = 'weapon'"  class="gtag-link-others" tagname="show_weapons_market">Show Weapons</b-button>
              </div>

              <div class="col">
                <b-button
                  variant="primary"
                  @click="activeType = 'character'"  class="gtag-link-others" tagname="show_characters_market">Show Characters</b-button>
              </div>

              <div class="col">
                <b-button
                  variant="primary"
                  v-if="activeType === 'weapon'"
                   class="gtag-link-others" tagname="add_listing_weapon"
                  :disabled="selectedNftId === null || selectedNftOnCooldown"
                  @click="showListingSetupModal()">List Weapon <b-icon-question-circle :hidden=!weaponMarketTax
                  v-tooltip.bottom="weaponMarketTax + '% tax (paid by the buyer) will be added to the final price.'"/></b-button>
                <b-button
                  variant="primary"
                  v-if="activeType === 'character'"
                  :disabled="selectedNftId === null || selectedNftOnCooldown"
                   class="gtag-link-others" tagname="add_listing_character"
                  @click="showListingSetupModal()">List Character <b-icon-question-circle :hidden=!characterMarketTax
                  v-tooltip.bottom="characterMarketTax + '% tax (paid by the buyer) will be added to the final price.'"/></b-button>

                <b-modal class="centered-modal" ref="listing-setup-modal"
                  @ok="addListingForNft">
                  <template #modal-title>
                    Sell {{activeType}}
                  </template>
                  <b-form-input class="modal-input" v-model="listingSellPrice" placeholder="Sell Price (SKILL)" />
                  <b-form-input class="modal-input" v-model="listingTargetBuyer" placeholder="Target Buyer Address (optional)" />
                </b-modal>
              </div>

              <div class="col">
              </div>

              <div class="col">
              </div>

              <div class="col">
              </div>
            </div>

            <div class="sell-grid" v-if="activeType === 'weapon'">
              <weapon-grid
                v-model="selectedNftId"
                :showReforgedToggle="false"
                :canFavorite="false"
              />
            </div>

            <div class="sell-grid" v-if="activeType === 'character'">
              <character-list
                :showFilters="true"
                v-model="selectedNftId"
              />
            </div>
          </div>
        </div>

        <div class="row">
          <div class="col">
            <div class="outcome" v-if="waitingMarketOutcome">
              <i class="fas fa-spinner fa-spin"></i>
              Loading...
            </div>

            <div class="outcome" v-if="marketOutcome !== null">{{ marketOutcome }}</div>
          </div>
        </div>
      </b-tab>
    </b-tabs>
  </div>
</template>

<script lang="ts">
import assert from 'assert';
import Vue from 'vue';
import { BModal } from 'bootstrap-vue';
import CharacterList from '../components/smart/CharacterList.vue';
import WeaponGrid from '../components/smart/WeaponGrid.vue';
import Hint from '../components/Hint.vue';
import Web3 from 'web3';
import { mapActions, mapGetters, mapState } from 'vuex';
import { Accessors } from 'vue/types/options';
import { Contract, Contracts, IState } from '../interfaces';
import { Characters, Weapons } from '../../../build/abi-interfaces';
import BigNumber from 'bignumber.js';

type SellType = 'weapon' | 'character';
type WeaponId = string;
type CharacterId = string;
type NftId = WeaponId | CharacterId;
const defaultTargetBuyer = '0x0000000000000000000000000000000000000000';

interface Data {
  activeType: SellType;
  search: string;
  searchResults: CharacterId[] | WeaponId[];
  allSearchResults: CharacterId[] | WeaponId[];
  searchResultsOwned: boolean;
  selectedNftId: NftId | null;
  marketOutcome: string | null;
  waitingMarketOutcome: boolean;
  nftPricesById: Record<string, string>;
  nftTargetBuyersById: Record<string, string>;
  characterMarketTax: string;
  weaponMarketTax: string;
  listingSellPrice: string;
  listingTargetBuyer: string;
}

type StoreMappedState = Pick<IState, 'defaultAccount' | 'weapons' | 'characters' | 'ownedCharacterIds' | 'ownedWeaponIds'>;

interface StoreMappedGetters {
  contracts: Contracts;
}

interface StoreMappedActions {
  fetchAllMarketNftIds(payload: { nftContractAddr: string }): Promise<string[]>;
  fetchMarketNftIdsBySeller(payload: { nftContractAddr: string, sellerAddr: string }): Promise<string[]>;
  fetchMarketNftPrice(payload: { nftContractAddr: string, tokenId: string | number }): Promise<string>;
  fetchMarketNftTargetBuyer(payload: { nftContractAddr: string, tokenId: string | number }): Promise<string>;
  fetchMarketTax(payload: { nftContractAddr: string }): Promise<string>;
  checkMarketItemOwnership(payload: { nftContractAddr: string, tokenId: string | number}): Promise<string>;
  addMarketListing(
    payload: { nftContractAddr: string, tokenId: string, price: string, targetBuyer: string }
  ): Promise<{ seller: string, nftID: string, price: string, targetBuyer: string }>;
  changeMarketListingPrice(
    payload: { nftContractAddr: string, tokenId: string, newPrice: string }
  ): Promise<{ seller: string, nftID: string, newPrice: string }>;
  changeMarketListingTargetBuyer(
    payload: { nftContractAddr: string, tokenId: string, newTargetBuyer: string }
  ): Promise<{ seller: string, nftID: string, newTargetBuyer: string }>;
  cancelMarketListing(payload: { nftContractAddr: string, tokenId: string }): Promise<{ seller: string, nftID: string }>;
  purchaseMarketListing(payload: { nftContractAddr: string, tokenId: string, maxPrice: string }): Promise<{ seller: string, nftID: string, price: string }>;
  fetchSellerOfNft(payload: { nftContractAddr: string, tokenId: string }): Promise<string>;
}

export default Vue.extend({
  components: { CharacterList, WeaponGrid, Hint },

  data() {
    return {
      activeType: 'weapon',
      search: '',
      searchResults: [],
      allSearchResults: [],
      searchResultsOwned: false,
      selectedNftId: null,
      marketOutcome: null,
      waitingMarketOutcome: false,
      nftPricesById: {},
      nftTargetBuyersById: {},
      characterMarketTax: '',
      weaponMarketTax: '',
      listingSellPrice: '',
      listingTargetBuyer: '',
    } as Data;
  },

  computed: {
    ...(mapState([
      'defaultAccount', 'weapons', 'characters', 'ownedCharacterIds', 'ownedWeaponIds'
    ]) as Accessors<StoreMappedState>),
    ...(mapGetters([
      'contracts'
    ]) as Accessors<StoreMappedGetters>),
    ...mapGetters(['transferCooldownOfWeaponId', 'transferCooldownOfCharacterId']),

    Weapons(): Contract<Weapons> {
      // we use x! here because we assert that they're set already in created()
      // this helps with typings
      return this.contracts.Weapons!;
    },

    Characters(): Contract<Characters> {
      // we use x! here because we assert that they're set already in created()
      // this helps with typings
      return this.contracts.Characters!;
    },

    contractAddress(): string {
      return this.activeType === 'weapon'
        ? this.Weapons.options.address
        : this.Characters.options.address;
    },

    buyableNftSelected(): boolean {
      return this.selectedNftId !== null
        && !this.searchResultsOwned;
    },

    ownListedNftSelected(): boolean {
      return this.selectedNftId !== null
        && this.searchResultsOwned;
    },

    selectedNftOnCooldown(): boolean {
      return this.selectedNftId !== null
      && (this.activeType === 'weapon'
        ? (this.transferCooldownOfWeaponId(+this.selectedNftId) > 0)
        : (this.transferCooldownOfCharacterId(+this.selectedNftId) > 0));
    },
  },

  methods: {
    ...(mapActions([
      'fetchAllMarketNftIds',
      'fetchMarketNftIdsBySeller',
      'fetchMarketNftPrice',
      'fetchMarketNftTargetBuyer',
      'fetchMarketTax',
      'checkMarketItemOwnership',
      'addMarketListing',
      'changeMarketListingPrice',
      'changeMarketListingTargetBuyer',
      'cancelMarketListing',
      'purchaseMarketListing',
      'fetchSellerOfNft',
    ]) as StoreMappedActions),

    clearData() {
      this.activeType = 'weapon';
      this.search = '';
      this.searchResults = [];
      this.allSearchResults = [];
      this.searchResultsOwned = false;
      this.selectedNftId = null;
      this.marketOutcome = null;
      this.waitingMarketOutcome = false;
      this.nftPricesById = {};
      this.nftTargetBuyersById = {};
      this.listingSellPrice = '';
      this.listingTargetBuyer = '';
    },

    showListingSetupModal() {
      this.clearInputs();
      (this.$refs['listing-setup-modal'] as BModal).show();
    },

    async loadMarketTaxes() {
      if(!this.characterMarketTax) {
        const tax = await this.getMarketTax(this.Characters.options.address) as string;
        this.characterMarketTax = this.convertMarketTax(tax);
      }
      if(!this.weaponMarketTax) {
        const tax = await this.getMarketTax(this.Weapons.options.address) as string;
        this.weaponMarketTax = this.convertMarketTax(tax);
      }
    },

    convertMarketTax(tax: string): string {
      return new BigNumber(tax).div(new BigNumber(2).pow(64)).multipliedBy(100).integerValue(BigNumber.ROUND_CEIL).toString();
    },

    async getMarketTax(contractAddress: string) {
      if(!contractAddress) return;

      return await this.fetchMarketTax({
        nftContractAddr: contractAddress,
      });
    },

    async lookupNftPrice(nftId: NftId) {
      if(!this.contractAddress) return;

      return await this.fetchMarketNftPrice({
        nftContractAddr: this.contractAddress,
        tokenId: nftId,
      });
    },

    async lookupNftTargetBuyer(nftId: NftId) {
      if(!this.contractAddress) return;

      return await this.fetchMarketNftTargetBuyer({
        nftContractAddr: this.contractAddress,
        tokenId: nftId,
      });
    },

    async fetchNftPrices(nftIds: NftId[]) {
      if(!this.contractAddress) return;

      await Promise.all(nftIds.map(async nftId => {
        const price = (await this.lookupNftPrice(nftId))!;

        void price;
        this.nftPricesById[nftId] = price;
      }));
    },

    async fetchNftTargetBuyers(nftIds: NftId[]) {
      if(!this.contractAddress) return;

      await Promise.all(nftIds.map(async nftId => {
        const targetBuyer = (await this.lookupNftTargetBuyer(nftId))!;

        void targetBuyer;
        this.nftTargetBuyersById[nftId] = targetBuyer;
      }));
    },

    async addListingForNft() {
      this.marketOutcome = null;
      if(this.selectedNftId === null) return;
      if(!this.listingSellPrice) return;

      const val = +this.listingSellPrice;
      if(val <= 0 || !val || isNaN(val)) return;

      this.waitingMarketOutcome = true;

      const results = await this.addMarketListing({
        nftContractAddr: this.contractAddress,
        tokenId: this.selectedNftId,
        price: this.convertSkillToWei(this.listingSellPrice),
        targetBuyer: this.listingTargetBuyer || defaultTargetBuyer
      });

      this.selectedNftId = null;
      this.waitingMarketOutcome = false;
      this.marketOutcome = 'Successfully listed '
        +this.activeType+' '+results.nftID+' for '+this.convertWeiToSkill(results.price)+' SKILL'
        +(this.listingTargetBuyer !== defaultTargetBuyer ? 'for ' + this.listingTargetBuyer : '');
    },

    async updateNftListingPrice() {

      this.marketOutcome = null;
      if(this.selectedNftId === null) return;


      const sellFor = await (this as any).$dialog.prompt({ title: `Sell ${this.activeType}`, text: 'Sell Price (SKILL)' });
      if(!sellFor) return;

      const val = +sellFor;
      if(val <= 0 || !val || isNaN(val)) return;

      this.waitingMarketOutcome = true;

      const results = await this.changeMarketListingPrice({
        nftContractAddr: this.contractAddress,
        tokenId: this.selectedNftId,
        newPrice: this.convertSkillToWei(sellFor)
      });

      this.selectedNftId = null;
      this.waitingMarketOutcome = false;
      this.marketOutcome = 'Successfully changed price for '
        +this.activeType+' '+results.nftID+' to '+this.convertWeiToSkill(results.newPrice)+' SKILL';
    },

    async updateNftListingTargetBuyer() {

      this.marketOutcome = null;
      if(this.selectedNftId === null) return;

      let targetBuyer = await (this as any).$dialog.prompt({ title: `Sell ${this.activeType}`, text: 'Target Buyer Address (optional)' });
      if(!targetBuyer) targetBuyer = defaultTargetBuyer;

      this.waitingMarketOutcome = true;

      const results = await this.changeMarketListingTargetBuyer({
        nftContractAddr: this.contractAddress,
        tokenId: this.selectedNftId,
        newTargetBuyer: targetBuyer
      });

      this.selectedNftId = null;
      this.waitingMarketOutcome = false;
      this.marketOutcome = 'Successfully changed target buyer for '
        +this.activeType+' '+results.nftID+' to '+results.newTargetBuyer;
    },

    async purchaseNft() {
      this.marketOutcome = null;
      if(this.selectedNftId === null) return;

      const price = await this.lookupNftPrice(this.selectedNftId);
      if(!price) return;

      const skillChainPrice = this.convertStringToDecimal(this.convertWeiToSkill(price), 2);
      const skillUIPrice = this.convertStringToDecimal(this.convertWeiToSkill(this.nftPricesById[this.selectedNftId]), 2);

      if(skillChainPrice !== skillUIPrice) {
        (this as any).$dialog.notify.error('The price of the listing has changed. Please refresh listing and try again');
        return;
      }

      this.waitingMarketOutcome = true;

      const results: any = await this.purchaseMarketListing({
        nftContractAddr: this.contractAddress,
        tokenId: this.selectedNftId,
        maxPrice: price
      });

      const results2: any  = await this.fetchAllMarketNftIds({
        nftContractAddr: this.contractAddress
      });

      this.allSearchResults = await this.filterOutTargetBuyers(results2) as string[];

      this.allSearchResults = Array.from(this.allSearchResults).filter((x: any) => x.id !== this.selectedNftId);

      this.waitingMarketOutcome = false;
      this.marketOutcome = 'Successfully purchased '
        +this.activeType+' '+results.nftID+' for '+this.convertWeiToSkill(results.price)+' SKILL'
          +' from '+results.seller;
    },

    async cancelNftListing() {
      this.marketOutcome = null;

      if(this.selectedNftId === null) return;

      this.waitingMarketOutcome = true;

      const results = await this.cancelMarketListing({
        nftContractAddr: this.contractAddress,
        tokenId: this.selectedNftId,
      });

      this.waitingMarketOutcome = false;
      this.marketOutcome = 'Successfully taken '
        +this.activeType+' '+results.nftID+' off the market.';

      await this.searchOwnListings(this.activeType);
    },

    async searchAllListingsByType(type: SellType) {
      this.activeType = type;
      this.marketOutcome = null;
      this.waitingMarketOutcome = true;

      const results = await this.fetchAllMarketNftIds({
        nftContractAddr: this.contractAddress
      });
      await this.fetchNftTargetBuyers(results);

      // searchResultsOwned does not mesh with this function
      // will need per-result checking of it, OR filtering out own NFTs
      //this.searchResultsOwned = nftSeller === this.defaultAccount;
      this.searchResultsOwned = false; // temp
      this.allSearchResults = await this.filterOutTargetBuyers(results) as string[];

      this.waitingMarketOutcome = false;
      this.marketOutcome = null;
    },

    async searchListingsByNftId(type: SellType) {
      this.activeType = type;
      this.marketOutcome = null;
      this.waitingMarketOutcome = true;

      const nftSeller = await this.fetchSellerOfNft({
        nftContractAddr: this.contractAddress,
        tokenId: this.search
      });
      this.searchResultsOwned = nftSeller === this.defaultAccount;

      const price = await this.lookupNftPrice(this.search);
      if(price !== '0') {
        this.searchResults = await this.filterOutTargetBuyers([this.search]) as string[];
      } else {
        this.searchResults = [];
      }

      this.waitingMarketOutcome = false;
      this.marketOutcome = null;
    },

    async searchListingsBySeller(type: SellType) {
      this.activeType = type;
      this.marketOutcome = null;
      this.waitingMarketOutcome = true;

      try {
        const result = await this.fetchMarketNftIdsBySeller({
          nftContractAddr: this.contractAddress,
          sellerAddr: this.search,
        });

        this.searchResultsOwned = this.search === this.defaultAccount;
        this.waitingMarketOutcome = false;
        this.searchResults = await this.filterOutTargetBuyers(result) as string[];

      } catch {
        this.searchResultsOwned = false;
        this.waitingMarketOutcome = false;
        this.searchResults = [];
      }
    },

    async searchOwnListings(type: SellType) {
      this.marketOutcome = null;
      this.activeType = type;

      if(!this.defaultAccount) {
        this.searchResults = [];
        return;
      }

      this.waitingMarketOutcome = true;

      const result = await this.fetchMarketNftIdsBySeller({
        nftContractAddr: this.contractAddress,
        sellerAddr: this.defaultAccount,
      });
      this.searchResultsOwned = true;
      this.waitingMarketOutcome = false;
      this.searchResults = result;
    },

    async filterOutTargetBuyers(nftIds: NftId[]) {
      if(!this.contractAddress) return;
      const results: string[] = [];

      await Promise.all(nftIds.map(async nftId => {
        const targetBuyer = (await this.lookupNftTargetBuyer(nftId))!;
        if(targetBuyer === defaultTargetBuyer || targetBuyer === this.defaultAccount) {
          results.push(nftId);
        }
      }));

      return results;
    },

    clearInputs() {
      this.listingSellPrice = '';
      this.listingTargetBuyer = '';
    },

    convertWeiToSkill(wei: string) {
      return Web3.utils.fromWei(
        wei,
        'ether'
      );
    },
    convertSkillToWei(skill: string) {
      return Web3.utils.toWei(
        skill,
        'ether'
      );
    },
    convertStringToDecimal(val: string, maxDecimals: number) {
      return new BigNumber(val).toFixed(maxDecimals);
    }
  },

  watch: {

    async searchResults(nftIds: CharacterId[] | WeaponId[]) {
      this.selectedNftId = null;

      await this.fetchNftPrices(nftIds);
    },

    async allSearchResults(nftIds: CharacterId[] | WeaponId[]) {
      this.selectedNftId = null;

      await this.fetchNftPrices(nftIds);
    }
  },

  filters: {
    maxDecimals(val: string, maxDecimals: number) {
      return new BigNumber(val).toFixed(maxDecimals);
    }
  },

  mounted() {
    assert.ok(this.contracts.Weapons && this.contracts.Characters, 'Expected required contracts to be available');
  },
});
</script>

<style scoped>
.body {
  margin-top: 10px;
}

.button + .button {
  margin-left: 10px;
}

.search {
  width: 100%;
}

.search-buttons, .self-buttons {
  margin-top: 10px;
  display: flex;
  justify-content: space-around;
}

.result-item {
  max-width: 12em;
}

.result-selected {
  outline: solid currentcolor 2px;
}

.sell-grid {
  display: flex;
  justify-content: center;
  flex-direction: column;
}

.outcome {
  margin: auto;
  text-align: center;
  font-size: 1em;
}

.modal-input {
  margin-bottom: 5px;
  margin-top: 5px;
}

</style>
