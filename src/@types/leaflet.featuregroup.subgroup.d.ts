import L from 'leaflet';
// in the global namesapce "L"
declare module 'leaflet' {
  /** Class for SubGroup */
  class SubGroup extends L.FeatureGroup {
    /** Changes the parent group into which child markers are added to / removed from. */
    setParentGroup(parentGroup: L.Layer): this;
    /** Removes the current sub-group from map before changing the parent group. Re-adds the sub-group to map if it was before changing. */
    setParentGroupSafe(parentGroup: L.Layer): this;
    /** Returns the current parent group. */
    getParentGroup(): L.Layer;
  }

  /** The factory is under leaflet.featureGroup.subGroup */
  namespace featureGroup {
    export function subGroup(
      parentGroup?: L.Layer,
      layersArray?: L.Layer[]
    ): SubGroup;
  }
}
