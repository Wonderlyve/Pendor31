import React, { useState } from 'react';
import { Plus, Newspaper, TrendingUp } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';

interface FloatingMenuProps {
  onCreatePost: () => void;
  onCreateNews: () => void;
}

export default function FloatingMenu({ onCreatePost, onCreateNews }: FloatingMenuProps) {
  const [isOpen, setIsOpen] = useState(false);
  const { user } = useAuth();
  const navigate = useNavigate();

  const handleClick = (action: () => void) => {
    if (!user) {
      navigate('/login');
      return;
    }
    action();
    setIsOpen(false);
  };

  return (
    <div className="fixed bottom-20 right-4 z-40">
      {isOpen && (
        <div className="flex flex-col gap-2 mb-4">
          <button
            onClick={() => handleClick(onCreateNews)}
            className="bg-green-600 text-white p-3 rounded-full shadow-lg hover:bg-green-700 transition-colors flex items-center gap-2"
            title="Créer une actualité"
          >
            <span className="bg-white text-green-600 px-2 py-1 rounded-full text-sm font-medium">Actualité</span>
            <Newspaper className="h-6 w-6" />
          </button>
          <button
            onClick={() => handleClick(onCreatePost)}
            className="bg-blue-600 text-white p-3 rounded-full shadow-lg hover:bg-blue-700 transition-colors flex items-center gap-2"
            title="Créer un pronostic"
          >
            <span className="bg-white text-blue-600 px-2 py-1 rounded-full text-sm font-medium">Pronostic</span>
            <TrendingUp className="h-6 w-6" />
          </button>
        </div>
      )}
      <button
        onClick={() => setIsOpen(!isOpen)}
        className={`bg-primary text-white p-3 rounded-full shadow-lg hover:bg-opacity-90 transition-all transform ${isOpen ? 'rotate-45' : ''}`}
      >
        <Plus className="h-6 w-6" />
      </button>
    </div>
  );
}