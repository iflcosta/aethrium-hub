export interface MockItem {
  id: number;
  name: string;
  type: "sword" | "axe" | "shield" | "armor" | "helmet" | "legs" | "boots" | "amulet" | "ring" | "potion" | "rune" | "misc";
  weight: number;
  attack?: number;
  defense?: number;
  armor?: number;
  description: string;
  flags: {
    stackable: boolean;
    pickupable: boolean;
    moveable: boolean;
    blocksolid: boolean;
    useable: boolean;
  };
}

export const mockItems: MockItem[] = [
  { id: 2400, name: "Magic Plate Armor", type: "armor", weight: 85, defense: 0, armor: 17, description: "A magic plate armor of exceptional quality.", flags: { stackable: false, pickupable: true, moveable: true, blocksolid: false, useable: false } },
  { id: 2431, name: "Demon Helmet", type: "helmet", weight: 42, armor: 10, description: "A helmet forged in demonic fire.", flags: { stackable: false, pickupable: true, moveable: true, blocksolid: false, useable: false } },
  { id: 2390, name: "Magic Plate Legs", type: "legs", weight: 60, armor: 9, description: "Powerful leg armor imbued with magic.", flags: { stackable: false, pickupable: true, moveable: true, blocksolid: false, useable: false } },
  { id: 2195, name: "Boots of Haste", type: "boots", weight: 7, armor: 2, description: "Boots that increase movement speed.", flags: { stackable: false, pickupable: true, moveable: true, blocksolid: false, useable: false } },
  { id: 2514, name: "Mastermind Shield", type: "shield", weight: 57, defense: 37, description: "A shield that protects the mind.", flags: { stackable: false, pickupable: true, moveable: true, blocksolid: false, useable: false } },
  { id: 2393, name: "Giant Sword", type: "sword", weight: 100, attack: 50, description: "A massive two-handed sword.", flags: { stackable: false, pickupable: true, moveable: true, blocksolid: false, useable: false } },
  { id: 2432, name: "Fire Axe", type: "axe", weight: 62, attack: 44, description: "An axe engulfed in flames.", flags: { stackable: false, pickupable: true, moveable: true, blocksolid: false, useable: false } },
  { id: 2173, name: "Amulet of Loss", type: "amulet", weight: 5, description: "Prevents item loss upon death.", flags: { stackable: false, pickupable: true, moveable: true, blocksolid: false, useable: true } },
  { id: 2214, name: "Ring of Healing", type: "ring", weight: 1, description: "Regenerates health over time.", flags: { stackable: false, pickupable: true, moveable: true, blocksolid: false, useable: true } },
  { id: 2273, name: "Ultimate Healing Rune", type: "rune", weight: 1, description: "Heals a large amount of HP.", flags: { stackable: true, pickupable: true, moveable: true, blocksolid: false, useable: true } },
  { id: 2293, name: "Mana Potion", type: "potion", weight: 2, description: "Restores 100-200 mana points.", flags: { stackable: true, pickupable: true, moveable: true, blocksolid: false, useable: true } },
  { id: 2160, name: "Aethrium Crystal", type: "misc", weight: 3, description: "A rare crystal pulsing with energy.", flags: { stackable: true, pickupable: true, moveable: true, blocksolid: false, useable: false } },
  { id: 2376, name: "Golden Crown", type: "helmet", weight: 20, armor: 5, description: "A crown worn by royalty.", flags: { stackable: false, pickupable: true, moveable: true, blocksolid: false, useable: false } },
  { id: 2418, name: "Dragon Scale Mail", type: "armor", weight: 72, armor: 15, description: "Armor crafted from dragon scales.", flags: { stackable: false, pickupable: true, moveable: true, blocksolid: false, useable: false } },
  { id: 2646, name: "Golden Mug", type: "misc", weight: 8, description: "A shiny golden mug.", flags: { stackable: false, pickupable: true, moveable: true, blocksolid: false, useable: false } },
  { id: 2152, name: "Soul Stone", type: "misc", weight: 1, description: "Stores souls for rune crafting.", flags: { stackable: false, pickupable: true, moveable: true, blocksolid: false, useable: true } },
  { id: 2520, name: "Blessed Shield", type: "shield", weight: 68, defense: 40, description: "A holy shield blessed by the gods.", flags: { stackable: false, pickupable: true, moveable: true, blocksolid: false, useable: false } },
  { id: 2407, name: "Bright Sword", type: "sword", weight: 33, attack: 36, description: "A sword that glows with inner light.", flags: { stackable: false, pickupable: true, moveable: true, blocksolid: false, useable: false } },
  { id: 2286, name: "Sudden Death Rune", type: "rune", weight: 1, description: "Causes devastating dark damage.", flags: { stackable: true, pickupable: true, moveable: true, blocksolid: false, useable: true } },
  { id: 7440, name: "Dodge Stone", type: "misc", weight: 2, description: "Grants a chance to dodge attacks.", flags: { stackable: false, pickupable: true, moveable: true, blocksolid: false, useable: true } },
];
