// @flow
import React from 'react';
import PropTypes from 'prop-types';
import type { PictureItem, Lang } from '../pages/helpers/types.js';
import Picture from './picture';

type PictureOverlayPropType = {
  picture: PictureItem,
  srcPrefix?: string,
  lang: Lang,
  closeCallback: Function,
};

export default class PictureOverlay extends React.Component {
  props: PictureOverlayPropType;
  onKeyUp: Function;
  hideOverlay: Function;

  static contextTypes = {
    showPictureOverlay: PropTypes.func,
    hidePictureOverlay: PropTypes.func,
  };

  constructor(props: PictureOverlayPropType) {
    super(props);
    this.onKeyUp = this.onKeyUp.bind(this);
    this.hideOverlay = this.hideOverlay.bind(this);
  }

  componentDidMount() {
    // eslint-disable-next-line no-undef
    document.addEventListener('keyup', this.onKeyUp, false);
    // eslint-disable-next-line no-undef
    document.body.classList.add('noscroll');
  }

  componentWillUnmount() {
    // eslint-disable-next-line no-undef
    document.removeEventListener('keyup', this.onKeyUp, false);
    // eslint-disable-next-line no-undef
    if (document.body != null) {
      document.body.classList.remove('noscroll');
    }
  }

  onKeyUp(e: KeyboardEvent) {
    if (e.keyCode === 27) {
      this.hideOverlay(e);
    }
  }

  hideOverlay(e: Event) {
    e.preventDefault();
    this.props.closeCallback();
  }

  eatClick(e: MouseEvent) {
    e.stopPropagation();
  }

  componentDidMount() {
    console.log('Overlay did mount');
  }
  render() {
    const { picture, srcPrefix } = this.props;
    return (
      <div className="overlay-background" onClick={this.hideOverlay}>
        <div className="overlay-container" onClick={this.eatClick}>
          <Picture picture={picture} srcPrefix={srcPrefix} />
        </div>
        <style jsx>{`
          .overlay-background {
            position: fixed;
            left: 0;
            right: 0;
            top: 0;
            bottom: 0;
            background-color: rgba(255, 255, 255, 0.9);
            overflow-y: scroll;
          }

          .overlay-background .overlay-container {
            position: absolute;
            left: 50%;
            top: 50%;
            width: 80%;
            height: 80%;
            transform: translate(-50%, -50%);
            max-width: 80vh;
            max-height: 80vh;
            z-index: 999;

            /* Just for the overlay-close with position: absolute below */
          }

          .overlay-container .overlay-close {
            width: 30px;
            height: 30px;
            cursor: pointer;
            position: absolute;
            right: -15px;
            top: -15px;
          }

          .overlay-container .overlay-close svg {
            display: block;
          }

          .overlay-container .overlay-close svg .button-overlay:hover {
            fill: rgba(0, 0, 0, 0.05);
          }

          .noscroll {
            overflow: hidden;
          }
        `}</style>
      </div>
    );
  }
}