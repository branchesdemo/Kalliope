// @flow

import React from 'react';
import Link from 'next/link';
import Head from '../components/head';
import Nav from '../components/nav';
import LangSelect from '../components/langselect';
import { PoetTabs } from '../components/tabs.js';
import Heading from '../components/heading.js';
import SubHeading from '../components/subheading.js';
import PoetName from '../components/poetname.js';
import TextName from '../components/textname.js';
import Note from '../components/note.js';
import * as Links from '../components/links';
import type { Lang, Poet, Work, Text } from './helpers/types.js';
import 'isomorphic-fetch';
import * as Paths from './helpers/paths.js';

const renderBody = (content_html: string) => {
  return content_html.replace(/\n/g, '<br/>');
};

export default class extends React.Component {
  props: {
    lang: Lang,
    poet: Poet,
    work: Work,
    text: Text,
  };

  static async getInitialProps({
    query: { lang, textId },
  }: {
    query: { lang: Lang, textId: string },
  }) {
    const path = Paths.textPath(textId);
    const res = await fetch(`http://localhost:3000/${path}`);
    const json: {
      poet: Poet,
      work: Work,
      text: Text,
    } = await res.json();
    return {
      lang,
      poet: json.poet,
      work: json.work,
      text: json.text,
    };
  }

  render() {
    const { lang, poet, work, text } = this.props;

    const renderedNotes = text.notes.map((note, i) => {
      return <Note key={i} note={note} />;
    });
    const sidebar = <div>{renderedNotes}</div>;
    const body = renderBody(text.content_html);

    const title = <PoetName poet={poet} includePeriod />;
    return (
      <div>
        <Head title="Digtere - Kalliope" />

        <div className="row">
          <Nav lang={lang} poet={poet} work={work} text={text} />
          <Heading title={title} subtitle="Værker" />
          <PoetTabs lang={lang} poet={poet} selected="works" />
          <div className="sidebar-split">
            <div>
              <SubHeading><TextName text={text} /></SubHeading>
              <div className="text-content">
                <div dangerouslySetInnerHTML={{ __html: body }} />
              </div>
            </div>
            <div>{sidebar}</div>
          </div>
          <LangSelect lang={lang} />
        </div>
      </div>
    );
  }
}
